variable "iam_lambda_role_arn" {
  description = "The name of the IAM role for the Lambda function."
  type        = string
}

variable "lambda_zip_file" {
  description = "The path to the Lambda function deployment package"
  type        = string
}

variable "rds_host" {
  description = "The hostname of the RDS instance."
  type        = string
}

variable "rds_port" {
  description = "The port of the RDS instance."
  type        = number
}

variable "db_name" {
  description = "The name of the database."
  type        = string
}

variable "db_username" {
  description = "The username for the database."
  type        = string
}

variable "rds_password" {
  description = "The password for the database."
  type        = string
  sensitive   = true
}

variable "bucket_name" {
  description = "The name of the S3 bucket containing the SQL dump and lambda layer."
  type        = string
}

variable "db_dump_s3_key" {
  description = "The S3 object key for the SQL dump file."
  type        = string
}

variable "lambda_layer_s3_key" {
  description = "The S3 object key for the lambda_layer."
  type        = string
}

variable "region" {
  description = "The AWS region."
  type        = string
}

variable "db_identifier" {
  description = "The name of the RDS instance"
  type        = string
}

variable "rds_arn" {
  description = "The ARN of the RDS instance."
  type        = string
}

variable "lambda_security_group_id" {
  description = "The security group IDs for the Lambda function."
  type        = string
}

variable "db_subnet_ids" {
  description = "The subnet IDs for the Lambda function."
  type        = list(string)
}

variable "private_subnet_azs" {
  description = "The Availability Zones of the private subnets."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "The Availability Zones of the private subnets."
  type        = list(string)
}

variable "rds_az" {
  description = "The Availability Zone of the RDS instance."
  type        = string
}
