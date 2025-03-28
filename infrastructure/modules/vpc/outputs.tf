output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC."
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "The IDs of the public subnets."
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "The IDs of the private subnets."
}

output "private_subnet_azs" {
  description = "List of Availability Zones for private subnets."
  value       = aws_subnet.private[*].availability_zone
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.gw.id
  description = "The ID of the Internet Gateway."
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.main.name
  description = "The name of DB Subnet Group"
}

output "db_subnet_ids" {
  value       = aws_db_subnet_group.main.subnet_ids
  description = "The IDs of db subnets."
}