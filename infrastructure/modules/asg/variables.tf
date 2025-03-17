variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
}

variable "public_subnet_ids" {
  description = "List of public subnets for ASG"
  type        = list(string)
}

variable "launch_template_id" {
  description = "Launch template ID"
  type        = string
}

variable "ec2_name" {
  description = "Tag name for instances"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of ALB Target Group"
  type        = string
}
