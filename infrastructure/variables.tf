variable "region" {
  description = "AWS region to deploy the resources."
  type        = string
  default     = "eu-central-1"
}

variable "role_arn" {
  description = "The ARN of the IAM role to assume for AWS authentication"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "main-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "allowed_ssh_ip" {
  description = "The IP address that is allowed to SSH into the EC2 instances"
  type        = string
  default     = "0.0.0.0/0" # Set your actual IP in terraform.tfvar
}

variable "alb_ingress_ports" {
  description = "Ports for the ALB security group ingress."
  type        = list(number)
  default     = [80, 443]
}

variable "ec2_ingress_ports" {
  description = "Ports for the EC2 security group ingress."
  type        = list(number)
  default     = [5000, 22]
}

variable "rds_port" {
  description = "The port number for the PostgreSQL RDS instance"
  type        = number
  default     = 5432
}

variable "iam_ec2_role_name" {
  description = "The name of the IAM role for EC2"
  type        = string
  default     = "EC2Role"
}

variable "iam_instance_profile_name" {
  description = "The name of the IAM instance profile"
  type        = string
  default     = "ec2-profile"
}

variable "launch_template_name" {
  description = "The name of the EC2 launch template"
  type        = string
  default     = "ec2-launch-template"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances."
  type        = string
  default     = "ami-0b74f796d330ab49c"
}

variable "key_name" {
  description = "The key pair name for SSH access"
  type        = string
}

variable "instance_type" {
  description = "Instance type for EC2."
  type        = string
  default     = "t2.micro"
}

variable "volume_size" {
  description = "Size of the EBS volume"
  type        = number
  default     = 20
}

variable "volume_type" {
  description = "Type of the EBS volume"
  type        = string
  default     = "gp3"
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
  default     = "asg"
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 4
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "ec2_name" {
  description = "Tag name for instances"
  type        = string
  default     = "grocery-ec2"
}

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = "grocery-alb"
}

variable "target_group_name" {
  description = "Name of the Target Group"
  type        = string
  default     = "alb-tg"
}

variable "target_group_port" {
  description = "Port for the Target Group"
  type        = number
  default     = 5000
}

variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/health"
}

variable "snapshot_id" {
  description = "The snapshot ID to restore the RDS instance from (optional)"
  type        = string
  default     = null
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     ="grocery_user"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     ="grocerymate_db"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_identifier" {
  description = "The name of the RDS instance"
  type        = string
  default     ="grocery-db"
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "aws-grocery-s3-v1" # Be sure to set unique name!!!
}

variable "versioning_status" {
  description = "The versioning status of the S3 bucket"
  type        = string
  default     = "Disabled"
}

variable "lifecycle_status" {
  description = "Lifecycle policy status"
  type        = string
  default     = "Disabled"
}

variable "expiration_days" {
  description = "The number of days to wait before deleting objects"
  type        = number
  default     = 30
}

variable "block_public_acls" {
  description = "Whether to block public ACLs"
  type        = bool
  default     = false
}

variable "block_public_policy" {
  description = "Whether to block public policy"
  type        = bool
  default     = false
}

variable "ignore_public_acls" {
  description = "Whether to ignore public ACLs"
  type        = bool
  default     = false
}

variable "restrict_public_buckets" {
  description = "Whether to restrict public buckets"
  type        = bool
  default     = false
}

variable "avatar_prefix" {
  description = "The prefix for the avatars storage path"
  type        = string
  default     = "avatars/"
}

variable "avatar_filename" {
  description = "The default avatar filename"
  type        = string
  default     = "user_default.png"
}

variable "avatar_path" {
  description = "Path to the local default avatar image file"
  type        = string
  default     = "../backend/avatar/user_default.png"
}

variable "db_dump_prefix" {
  description = "Prefix for database dump file"
  type        = string
  default     = "db_backups/"
}

variable "db_dump_filename" {
  description = "Filename for database dump"
  type        = string
  default     = "sqlite_dump_clean.sql"
}

variable "db_dump_path" {
  description = "Local path to SQLite dump file"
  type        = string
  default     = "../backend/app/sqlite_dump_clean.sql"
}

variable "layer_prefix" {
  description = "Prefix for database dump file"
  type        = string
  default     = "lambda_layers/"
}

variable "layer_filename" {
  description = "Filename for database dump"
  type        = string
  default     = "boto3-psycopg2-layer.zip"
}

variable "layer_path" {
  description = "Local path to SQLite dump file"
  type        = string
  default     = "lambda_layers/boto3-psycopg2-layer.zip"
}

variable "lambda_zip_file" {
  description = "The path to the Lambda function deployment package"
  type        = string
  default     = "lambda_data/lambda_function.zip"  # Default value, can be overridden
}

variable "iam_lambda_role_name" {
  description = "IAM role name for Lambda"
  type        = string
  default     = "LambdaRole"
}