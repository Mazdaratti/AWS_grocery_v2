variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group for the ALB"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnets"
  type        = list(string)
}

variable "target_group_name" {
  description = "Name of the Target Group"
  type        = string
}

variable "target_group_port" {
  description = "Port for the Target Group"
  type        = number
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
}
