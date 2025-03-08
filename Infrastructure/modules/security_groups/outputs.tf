output "alb_security_group_id" {
  value = aws_security_group.alb_sg.id
  description = "The ID of the ALB security group"
}

output "ec2_security_group_id" {
  value = aws_security_group.ec2_sg.id
  description = "The ID of the EC2 security group"
}

output "rds_security_group_id" {
  value = aws_security_group.rds_sg.id
  description = "The ID of the RDS security group"
}