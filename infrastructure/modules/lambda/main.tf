# ======================
# Lambda Layer
# ======================

# Create a Lambda layer containing dependencies (e.g., boto3, psycopg2)
resource "aws_lambda_layer_version" "my_layer" {
  layer_name          = "boto3-psycopg2-layer"  # Name of the Lambda layer
  description         = "My custom Lambda layer"  # Description of the layer
  compatible_runtimes = ["python3.12"]  # Compatible Python runtime

  s3_bucket = var.bucket_name  # S3 bucket where the layer code is stored
  s3_key    = var.lambda_layer_s3_key  # S3 key for the layer code
}

# ======================
# CloudWatch Log Groups
# ======================

# Create a CloudWatch Log Group for the Lambda function
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/db_populator"  # Static name for the log group
  retention_in_days = 7  # Retain logs for 7 days
}

# Create a CloudWatch Log Group for the Step Function
resource "aws_cloudwatch_log_group" "step_function_log_group" {
  name              = "/aws/vendedlogs/states/db-restore-step-function"  # Log group name
  retention_in_days = 7  # Retain logs for 7 days
}

# ======================
# Lambda Function
# ======================

# Create the Lambda function to populate the RDS database
resource "aws_lambda_function" "db_populator" {
  function_name = "db_populator"  # Name of the Lambda function
  role          = var.iam_lambda_role_arn  # IAM role for the Lambda function
  handler       = "lambda_function.lambda_handler"  # Entry point for the Lambda function
  runtime       = "python3.12"  # Python runtime for the Lambda function
  timeout       = 60  # Timeout in seconds
  filename      = var.lambda_zip_file  # Path to the Lambda function code
  source_code_hash = filebase64sha256(var.lambda_zip_file)  # Hash of the Lambda code
  layers = [aws_lambda_layer_version.my_layer.arn]  # Attach the Lambda layer

  # Configure VPC access for the Lambda function
  vpc_config {
    subnet_ids         = var.private_subnet_ids  # Private subnets for the Lambda function
    security_group_ids = [var.lambda_security_group_id]  # Security group for the Lambda function
  }

  # Set environment variables for the Lambda function
  environment {
    variables = {
      POSTGRES_HOST     = var.rds_host  # RDS database host
      POSTGRES_PORT     = var.rds_port  # RDS database port
      POSTGRES_DB       = var.db_name  # RDS database name
      POSTGRES_USER     = var.db_username  # RDS database username
      POSTGRES_PASSWORD = var.rds_password  # RDS database password
      S3_BUCKET_NAME    = var.bucket_name  # S3 bucket name
      S3_OBJECT_KEY     = var.db_dump_s3_key  # S3 key for the SQLite dump file
      S3_REGION         = var.region  # AWS region
    }
  }

  # Ensure the log group is created before the Lambda function
  depends_on = [aws_cloudwatch_log_group.lambda_log_group]
}

# ======================
# Step Function
# ======================

# Create a Step Function to orchestrate the database population process
resource "aws_sfn_state_machine" "db_restore_sfn" {
  name     = "db-restore-step-function"  # Name of the Step Function
  role_arn = aws_iam_role.sfn_role.arn  # IAM role for the Step Function

  # Step Function definition (JSON)
  definition = jsonencode({
    Comment = "Step function to trigger Lambda after RDS is ready and SQL dump is in S3.",
    StartAt = "WaitForRDS",
    States = {
      WaitForRDS = {
        Type = "Task",
        Resource = "arn:aws:states:::aws-sdk:rds:describeDBInstances",
        Parameters = {
          DbInstanceIdentifier = var.db_identifier
        },
        ResultPath = "$.output",
        Next = "LogRDSOutput",
        Catch = [
          {
            ErrorEquals = ["States.ALL"],
            Next = "HandleRDSFailure"
          }
        ]
      },
      LogRDSOutput = {
        Type       = "Pass",
        ResultPath = "$.output",
        Next       = "CheckRDSStatus"
      },
      CheckRDSStatus = {
        Type = "Choice",
        Choices = [
          {
            Variable = "$.output.output.DbInstances[0].DbInstanceStatus",
            StringEquals = "available",
            Next = "CheckS3File"
          }
        ],
        Default = "HandleRDSFailure"
      },
      CheckS3File = {
        Type = "Task",
        Resource = "arn:aws:states:::aws-sdk:s3:headObject",
        Parameters = {
          Bucket = var.bucket_name,
          Key = var.db_dump_s3_key
        },
        Next = "CheckS3FileExists",
        Catch = [
          {
            ErrorEquals = ["States.ALL"],
            Next = "HandleS3Failure"
          }
        ]
      },
      CheckS3FileExists = {
        Type = "Choice",
        Choices = [
          {
            "Variable": "$.ContentLength",
            "NumericGreaterThan": 0,
            Next = "TriggerLambda"
          }
        ],
        Default = "WaitForS3File"
      },
      WaitForS3File = {
        Type = "Wait",
        Seconds = 60,
        Next = "CheckS3File"
      },
      TriggerLambda = {
        Type = "Task",
        Resource = aws_lambda_function.db_populator.arn,
        End = true,
        Catch = [
          {
            ErrorEquals = ["States.ALL"],
            Next = "HandleLambdaFailure"
          }
        ]
      },
      HandleRDSFailure = {
        Type = "Fail",
        Cause = "RDS instance check failed.",
        Error = "RDSFailure"
      },
      HandleS3Failure = {
        Type = "Fail",
        Cause = "S3 file check failed.",
        Error = "S3Failure"
      },
      HandleLambdaFailure = {
        Type = "Fail",
        Cause = "Lambda function execution failed.",
        Error = "LambdaFailure"
      }
    }
  })

  # Configure logging for the Step Function
  logging_configuration {
    log_destination = "${aws_cloudwatch_log_group.step_function_log_group.arn}:*"
    level           = "ALL"  # Log all events
    include_execution_data = true  # Include execution data in the logs
  }

  # Ensure the CloudWatch Log Group is created before the Step Function
  depends_on = [aws_cloudwatch_log_group.step_function_log_group]
}

# ======================
# IAM Roles and Policies
# ======================

# Create an IAM role for the Step Function
resource "aws_iam_role" "sfn_role" {
  name = "step-functions-role"  # Name of the IAM role

  # Trust policy allowing Step Functions to assume the role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

# Create an IAM policy for the Step Function
resource "aws_iam_policy" "sfn_policy" {
  name        = "step-functions-policy"  # Name of the IAM policy
  description = "Policy for Step Functions to check RDS, S3, and invoke Lambda."

  # Policy document
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["rds:DescribeDBInstances"]
        Resource = var.rds_arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:HeadObject"]
        Resource = "arn:aws:s3:::${var.bucket_name}/${var.db_dump_s3_key}"
      },
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = aws_lambda_function.db_populator.arn
      },
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = [aws_cloudwatch_log_group.step_function_log_group.arn,
        "${aws_cloudwatch_log_group.step_function_log_group.arn}:*"]
      }
    ]
  })
}

# Attach the IAM policy to the Step Function role
resource "aws_iam_role_policy_attachment" "sfn_attach" {
  role       = aws_iam_role.sfn_role.name
  policy_arn = aws_iam_policy.sfn_policy.arn
}

# ======================
# EventBridge Rule
# ======================

# Create an EventBridge rule to trigger the Step Function when the SQL dump is uploaded to S3
resource "aws_cloudwatch_event_rule" "s3_upload_event" {
  name        = "s3-dump-uploaded"  # Name of the EventBridge rule
  description = "Trigger Step Function when a SQL dump is uploaded."

  # Event pattern to match S3 "Object Created" events
  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [var.bucket_name]
      }
      object = {
        key = [var.db_dump_s3_key]
      }
    }
  })
}

# Create an EventBridge target to trigger the Step Function when the SQL dump is uploaded to S3
resource "aws_cloudwatch_event_target" "step_function_trigger_s3" {
  rule      = aws_cloudwatch_event_rule.s3_upload_event.name
  target_id = "StepFunctionTriggerS3"
  arn       = aws_sfn_state_machine.db_restore_sfn.arn
  role_arn  = aws_iam_role.eventbridge_step_function_role.arn
}

# ======================
# IAM Role for EventBridge
# ======================

# Create an IAM role for EventBridge to trigger the Step Function
resource "aws_iam_role" "eventbridge_step_function_role" {
  name = "eventbridge-step-function-role"  # Name of the IAM role

  # Trust policy allowing EventBridge to assume the role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

# Create an IAM policy for EventBridge to start the Step Function
resource "aws_iam_policy" "eventbridge_step_function_policy" {
  name        = "eventbridge-step-function-policy"  # Name of the IAM policy
  description = "Allows EventBridge to start the Step Functions state machine."

  # Policy document
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "states:StartExecution"
        Resource = aws_sfn_state_machine.db_restore_sfn.arn
      }
    ]
  })
}

# Create an IAM policy for EventBridge to write logs to CloudWatch
resource "aws_iam_policy" "eventbridge_logging_policy" {
  name        = "eventbridge-logging-policy"  # Name of the IAM policy
  description = "Allows EventBridge to write logs to CloudWatch."

  # Policy document
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = aws_cloudwatch_log_group.step_function_log_group.arn
      }
    ]
  })
}

# Attach the IAM policies to the EventBridge role
resource "aws_iam_role_policy_attachment" "eventbridge_step_function_attach" {
  role       = aws_iam_role.eventbridge_step_function_role.name
  policy_arn = aws_iam_policy.eventbridge_step_function_policy.arn
}

resource "aws_iam_role_policy_attachment" "eventbridge_logging_attach" {
  role       = aws_iam_role.eventbridge_step_function_role.name
  policy_arn = aws_iam_policy.eventbridge_logging_policy.arn
}