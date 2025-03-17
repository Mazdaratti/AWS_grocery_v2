output "lambda_iam_role_arn" {
  description = "The ARN of the IAM role for Lambda"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_iam_role_name" {
  value       = aws_iam_role.lambda_role.name
  description = "The name of the IAM role."
}