# Lambda Layer Resource
resource "aws_lambda_layer_version" "my_layer" {
  layer_name          = "boto3-psycopg2-layer"
  description         = "My custom Lambda layer"
  compatible_runtimes = ["python3.12"]

  s3_bucket        = var.bucket_name
  s3_key           = var.lambda_layer_s3_key
}

# Lambda Function Resource
resource "aws_lambda_function" "db_populator" {
  function_name = "db_populator"
  role          = var.iam_lambda_role_arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60
  filename      = var.lambda_zip_file
  source_code_hash = filebase64sha256(var.lambda_zip_file)
  layers = [aws_lambda_layer_version.my_layer.arn]

  vpc_config {
    subnet_ids         = var.private_subnet_ids #local.rds_az
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      POSTGRES_HOST     = var.rds_host
      POSTGRES_PORT     = var.rds_port
      POSTGRES_DB       = var.db_name
      POSTGRES_USER     = var.db_username
      POSTGRES_PASSWORD = var.rds_password
      S3_BUCKET_NAME    = var.bucket_name
      S3_OBJECT_KEY     = var.db_dump_s3_key
      S3_REGION         = var.region
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.db_populator.function_name}"
  retention_in_days = 7  # Set the log retention period (e.g., 7 days)
}

# Step Functions State Machine
resource "aws_sfn_state_machine" "db_restore_sfn" {
  name     = "db-restore-step-function"
  role_arn = aws_iam_role.sfn_role.arn

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
            ErrorEquals = ["States.ALL"],  # Catch all errors
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
            ErrorEquals = ["States.ALL"],  # Catch all errors
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
  logging_configuration {
    log_destination = "${aws_cloudwatch_log_group.step_function_log_group.arn}:*"
    level           = "ALL"  # Log all events (you can also use "ERROR" or "FATAL")
    include_execution_data = true  # Include execution data in the logs
  }
}

# IAM Role for Step Functions
resource "aws_iam_role" "sfn_role" {
  name = "step-functions-role"

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

# IAM Policy for Step Functions
resource "aws_iam_policy" "sfn_policy" {
  name        = "step-functions-policy"
  description = "Policy for Step Functions to check RDS, S3, and invoke Lambda."

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

# Attach Policies to Step Functions Role

resource "aws_iam_role_policy_attachment" "sfn_attach" {
  role       = aws_iam_role.sfn_role.name
  policy_arn = aws_iam_policy.sfn_policy.arn
}

resource "aws_cloudwatch_log_group" "step_function_log_group" {
  name              = "/aws/vendedlogs/states/db-restore-step-function"
  retention_in_days = 7  # Set the log retention period (e.g., 7 days)
}

# CloudWatch Event Rule for RDS Availability
resource "aws_cloudwatch_event_rule" "rds_ready" {
  name        = "rds-instance-ready"
  description = "Trigger Step Function when RDS is fully available."

  event_pattern = jsonencode({
    source      = ["aws.rds"]
    detail-type = ["RDS DB Instance Event"]
    detail = {
      EventID = ["RDS-EVENT-0088"]  # DB Instance Available
    }
  })
}

# CloudWatch Event Target to Trigger Step Function
resource "aws_cloudwatch_event_target" "step_function_trigger_rds" {
  rule      = aws_cloudwatch_event_rule.rds_ready.name
  target_id = "StepFunctionTriggerRDS"
  arn       = aws_sfn_state_machine.db_restore_sfn.arn
  role_arn  = aws_iam_role.eventbridge_step_function_role.arn
}

# EventBridge Rule for S3 Upload Events
resource "aws_cloudwatch_event_rule" "s3_upload_event" {
  name        = "s3-dump-uploaded"
  description = "Trigger Step Function when a SQL dump is uploaded."

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

# EventBridge Target to Trigger Step Function
resource "aws_cloudwatch_event_target" "step_function_trigger_s3" {
  rule      = aws_cloudwatch_event_rule.s3_upload_event.name
  target_id = "StepFunctionTriggerS3"
  arn       = aws_sfn_state_machine.db_restore_sfn.arn
  role_arn  = aws_iam_role.eventbridge_step_function_role.arn
}

resource "aws_iam_role" "eventbridge_step_function_role" {
  name = "eventbridge-step-function-role"

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

resource "aws_iam_policy" "eventbridge_step_function_policy" {
  name        = "eventbridge-step-function-policy"
  description = "Allows EventBridge to start the Step Functions state machine."

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

resource "aws_iam_policy" "eventbridge_logging_policy" {
  name        = "eventbridge-logging-policy"
  description = "Allows EventBridge to write logs to CloudWatch."

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

resource "aws_iam_role_policy_attachment" "eventbridge_step_function_attach" {
  role       = aws_iam_role.eventbridge_step_function_role.name
  policy_arn = aws_iam_policy.eventbridge_step_function_policy.arn
}

resource "aws_iam_role_policy_attachment" "eventbridge_logging_attach" {
  role       = aws_iam_role.eventbridge_step_function_role.name
  policy_arn = aws_iam_policy.eventbridge_logging_policy.arn
}