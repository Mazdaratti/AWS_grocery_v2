variable "identifier" {
  description = "The name of the RDS instance"
  type        = string
}

variable "snapshot_id" {
  description = "The snapshot identifier to restore from (optional)"
  type        = string
  default     = null
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
}

variable "storage_type" {
  description = "The type of storage to use (e.g., gp2, io1)"
  type        = string
}

variable "engine" {
  description = "The database engine to use (e.g., postgres, mysql)"
  type        = string
}

variable "engine_version" {
  description = "The version of the database engine"
  type        = string
}

variable "storage_encrypted" {
  description = "Whether to encrypt the storage"
  type        = bool
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection"
  type        = bool
}

variable "publicly_accessible" {
  description = "Whether the RDS instance is publicly accessible"
  type        = bool
}

variable "multi_az" {
  description = "Whether to enable multi-AZ deployment"
  type        = bool
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs to associate with the RDS instance"
  type        = list(string)
}

variable "db_subnet_group_name" {
  description = "The name of the DB subnet group"
  type        = string
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when deleting the RDS instance"
  type        = bool
}