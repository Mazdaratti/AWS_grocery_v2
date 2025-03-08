resource "aws_db_instance" "rds" {
  identifier             = var.identifier
  snapshot_identifier    = var.snapshot_id
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  storage_type           = var.storage_type
  engine                 = var.engine
  engine_version         = var.engine_version
  storage_encrypted      = var.storage_encrypted
  deletion_protection    = var.deletion_protection
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az
  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = var.db_subnet_group_name
  skip_final_snapshot    = var.skip_final_snapshot

  # Database credentials
  username = var.db_username
  password = var.db_password
  db_name  = var.db_name
}