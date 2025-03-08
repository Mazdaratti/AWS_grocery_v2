output "iam_role_name" {
  value       = aws_iam_role.ec2_role.name
  description = "The name of the IAM role."
}

output "iam_instance_profile_name" {
  value       = aws_iam_instance_profile.ec2_instance_profile.name
  description = "The name of the IAM instance profile."
}

output "iam_role_arn" {
  value       = aws_iam_role.ec2_role.arn
  description = "The ARN of the IAM role."
}