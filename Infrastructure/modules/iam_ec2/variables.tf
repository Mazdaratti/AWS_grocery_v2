variable "iam_ec2_role_name" {
  description = "The name of the IAM role for EC2"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "The name of the IAM instance profile"
  type        = string
}

variable "bucket_name" {
  description = "The name of the S3 bucket."
  type        = string
}

variable "folder_path" {
  description = "The folder path in the S3 bucket (e.g., 'avatar/')."
  type        = string
}