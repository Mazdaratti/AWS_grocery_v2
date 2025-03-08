# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/app/docker-logs"
  retention_in_days = 30 # Optional: Set log retention period
}

# Attach CloudWatchAgentServerPolicy to the IAM Role
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attachment" {
  role       = var.ec2_role_name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}