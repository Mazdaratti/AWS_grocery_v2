variable "iam_lambda_role_name" {
  description = "The name of the IAM role for the Lambda function."
  type        = string
}

variable "bucket_name" {
  description = "The name of the S3 bucket containing the SQL dump."
  type        = string
}

variable "db_dump_s3_key" {
  description = "The S3 object key for the SQL dump file."
  type        = string
}

variable "rds_arn" {
  description = "The ARN of the RDS instance."
  type        = string
}