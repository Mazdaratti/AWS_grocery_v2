output "ecr_repository_url" {
  value       = aws_ecr_repository.repos.repository_url
  description = "URL of the ECR repository."
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the created VPC."
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "List of public subnet IDs."
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "List of private subnet IDs."
}

output "internet_gateway_id" {
  value       = module.vpc.internet_gateway_id
  description = "The ID of the Internet Gateway."
}

output "db_subnet_group_name" {
  value       = module.vpc.db_subnet_group_name
  description = "The name of the database subnet group."
}

output "alb_security_group_id" {
  value       = module.security_groups.alb_security_group_id
  description = "The ID of the ALB security group."
}

output "ec2_security_group_id" {
  value       = module.security_groups.ec2_security_group_id
  description = "The ID of the EC2 security group."
}

output "rds_security_group_id" {
  value       = module.security_groups.rds_security_group_id
  description = "The ID of the RDS security group."
}

output "iam_ec2_role_name" {
  value       = module.iam_ec2.ec2_iam_role_name
  description = "The name of the IAM role."
}

output "ec2_iam_role_arn" {
  value       = module.iam_ec2.ec2_iam_role_arn
  description = "The ARN of the IAM role."
}

output "lambda_iam_role_name" {
  value       = module.iam_lambda.lambda_iam_role_name
  description = "The name of the IAM role."
}

output "lambda_iam_role_arn" {
  description = "The ARN of the IAM role for Lambda"
  value       = module.iam_lambda.lambda_iam_role_arn
}

output "iam_instance_profile_name" {
  value       = module.iam_ec2.iam_instance_profile_name
  description = "The name of the IAM instance profile."
}

output "launch_template_id" {
  value       = module.ec2_launch_template.launch_template_id
  description = "The ID of the EC2 launch template."
}

output "launch_template_name" {
  value       = module.ec2_launch_template.launch_template_name
  description = "The name of the EC2 launch template."
}

output "asg_id" {
  value       = module.asg.asg_id
  description = "The ID of the Auto Scaling Group."
}

output "alb_arn" {
  value       = module.alb.alb_arn
  description = "The ARN of the Application Load Balancer."
}

output "target_group_arn" {
  value       = module.alb.target_group_arn
  description = "The ARN of the Target Group for ALB."
}

output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "The DNS name of the Application Load Balancer."
}

output "rds_endpoint" {
  value       = module.rds.rds_endpoint
  description = "The endpoint of the RDS instance."
}

output "rds_host" {
  description = "The endpoint of the RDS instance"
  value       = module.rds.rds_host
}

output "rds_id" {
  description = "The ID of the RDS DB instance."
  value       = module.rds.rds_id
}

output "rds_arn" {
  description = "The ARN of the RDS instance"
  value       = module.rds.rds_arn
}

output "rds_az" {
  description = "The Availability Zone of the RDS instance"
  value       = module.rds.rds_az
}

output "lambda_function_name" {
  description = "The name of the Lambda function."
  value       = module.lambda.lambda_function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function."
  value       = module.lambda.lambda_function_arn
}

output "sfn_arn" {
  description = "The ARN of the Step Functions state machine."
  value       = module.lambda.sfn_arn
}

output "bucket_name" {
  value       = module.s3_bucket.bucket_name
  description = "The name of the S3 bucket"
}

output "bucket_id" {
  value       = module.s3_bucket.bucket_id
  description = "The ID of the created S3 bucket."
}

output "bucket_arn" {
  value       = module.s3_bucket.bucket_arn
  description = "The ARN of the created S3 bucket."
}

