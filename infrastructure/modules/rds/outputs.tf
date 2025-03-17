output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.rds.endpoint
}

output "rds_id" {
  description = "The ID of the RDS instance"
  value       = aws_db_instance.rds.id
}

output "rds_az" {
  description = "The Availability Zone of the RDS instance"
  value       = aws_db_instance.rds.availability_zone
}

output "rds_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.rds.arn
}

output "rds_host" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.rds.address
}