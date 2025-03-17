output "launch_template_id" {
  value       = aws_launch_template.grocery.id
  description = "The ID of the EC2 launch template."
}

output "launch_template_name" {
  value       = aws_launch_template.grocery.name
  description = "The name of the EC2 launch template."
}