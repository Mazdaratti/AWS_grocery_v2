variable "lambda_role_name" {
  description = "The name of the IAM role for Lambda"
  type        = string
}

variable "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  type        = string
}

variable "db_dump_s3_key" {
  description = "The S3 key (path) of the database dump file"
  type        = string
}
