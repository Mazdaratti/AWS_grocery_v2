variable "launch_template_name" {
  description = "The name of the EC2 launch template"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
}

variable "key_name" {
  description = "The key pair name for SSH access"
  type        = string
}

variable "instance_type" {
  description = "The instance type for the EC2 instance"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "The name of the IAM instance profile"
  type        = string
}

variable "security_group_id" {
  description = "The security group ID for the EC2 instance"
  type        = string
}

variable "volume_size" {
  description = "Size of the EBS volume"
  type        = number
}

variable "volume_type" {
  description = "Type of the EBS volume"
  type        = string
}
