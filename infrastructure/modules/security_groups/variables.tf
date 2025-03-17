variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "allowed_ssh_ip" {
  description = "The IP address that is allowed to SSH into the EC2 instances"
  type        = string
}

variable "alb_ingress_ports" {
  description = "Ports for the ALB security group ingress"
  type        = list(number)
}

variable "ec2_ingress_ports" {
  description = "Ports for the EC2 security group ingress"
  type        = list(number)
}

variable "rds_port" {
  description = "The port number for the PostgreSQL RDS instance"
  type        = number
  default     = 5432
}