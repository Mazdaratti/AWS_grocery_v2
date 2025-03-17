# Find the subnet in the same AZ as the RDS instance
locals {
  rds_az = var.rds_az  # Assuming the RDS module outputs the AZ
  lambda_subnet_id = [
    for subnet in var.db_subnet_ids : subnet
    if var.private_subnet_azs[index(var.private_subnet_ids, subnet)] == local.rds_az
  ][0]
}