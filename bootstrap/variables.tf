variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "github_org" {
  description = "Your GitHub organization or user name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "backend_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "grocery-terraform-state-v5"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  type        = string
  default     = "terraform-lock"
}