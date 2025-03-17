provider "aws" {
  region  = "eu-central-1"
  profile = "default"
}

# ECR Repositories
resource "aws_ecr_repository" "repos" {
  name     = "aws_grocery-app"
}

module "vpc" {
  source               = "./modules/vpc"
  region               = var.region
  vpc_cidr             = "10.0.0.0/16"
  vpc_name             = "grocery-vpc"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

module "security_groups" {
  source = "./modules/security_groups"

  vpc_id            = module.vpc.vpc_id
  allowed_ssh_ip    = var.allowed_ssh_ip # Set your local IP in terraform.tfvars
  alb_ingress_ports = [80, 443]
  ec2_ingress_ports = [5000, 22]
  rds_port          = 5432
}

module "iam_ec2" {
  source                    = "./modules/iam_ec2"
  iam_ec2_role_name             = "EC2Role"
  iam_instance_profile_name = "EC2Profile"
  bucket_name               = var.bucket_name
  folder_path               = var.avatar_prefix
}

module "iam_lambda" {
  source                    = "./modules/iam_lambda"
  iam_lambda_role_name      = "LambdaRole"
  bucket_name               = var.bucket_name
  db_dump_s3_key            = local.db_dump_s3_key
  rds_arn                   = module.rds.rds_arn
}

module "ec2_launch_template" {
  source                    = "./modules/ec2_launch_template"
  launch_template_name      = "grocery-launch-template"
  ami_id                    = var.ami_id
  instance_type             = "t2.micro"
  key_name                  = var.key_name # Set your Key Name in terraform.tfvars
  iam_instance_profile_name = module.iam_ec2.iam_instance_profile_name
  security_group_id         = module.security_groups.ec2_security_group_id
  volume_size               = 20
  volume_type               = "gp3"
  region                    = var.region
  ecr_repository_url        = aws_ecr_repository.repos.repository_url
  image_tag                 = "latest"
}

module "asg" {
  source             = "./modules/asg"
  asg_name           = "grocery-asg"
  desired_capacity   = 1 # adjust for desired capacity
  max_size           = 4 # adjust for desired max_size
  min_size           = 1 # adjust for desired min_size
  public_subnet_ids  = module.vpc.public_subnet_ids
  launch_template_id = module.ec2_launch_template.launch_template_id
  ec2_name           = "grocery-ec2"
  target_group_arn   = module.alb.target_group_arn
}

module "alb" {
  source                = "./modules/alb"
  alb_name              = "grocery-alb"
  alb_security_group_id = module.security_groups.alb_security_group_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  target_group_name     = "grocery-alb-tg"
  target_group_port     = 5000
  vpc_id                = module.vpc.vpc_id
  health_check_path     = "/health"
}

module "rds" {
  source                 = "./modules/rds"
  db_identifier          = "grocery-db"
  snapshot_id            = var.snapshot_id # Set the value of your snapshot ID in terraform.tfvars
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "17.4"
  storage_encrypted      = true
  deletion_protection    = false
  publicly_accessible    = false
  multi_az               = true
  vpc_security_group_ids = [module.security_groups.rds_security_group_id]
  db_subnet_group_name   = module.vpc.db_subnet_group_name
  skip_final_snapshot    = true

  # Database credentials (From terraform.tfvars)
  db_username = var.db_username
  db_password = var.db_password
  db_name     = var.db_name
}

module "lambda" {
  source = "./modules/lambda"

  iam_lambda_role_arn       = module.iam_lambda.lambda_iam_role_arn
  rds_host                  = module.rds.rds_host
  rds_port                  = var.rds_port
  db_name                   = var.db_name
  db_username               = var.db_username
  db_identifier             = var.db_identifier
  rds_password              = var.db_password
  bucket_name               = var.bucket_name
  db_dump_s3_key            = local.db_dump_s3_key
  lambda_layer_s3_key       = local.lambda_layer_s3_key
  region                    = var.region
  rds_arn                   = module.rds.rds_arn
  lambda_security_group_id  = module.security_groups.lambda_security_group_id
  db_subnet_ids             = module.vpc.db_subnet_ids
  private_subnet_azs        = module.vpc.private_subnet_azs
  private_subnet_ids        = module.vpc.private_subnet_ids
  rds_az                    = module.rds.rds_az
  lambda_zip_file           = "lambda_data/lambda_function.zip"
}

module "s3_bucket" {
  source                  = "./modules/s3_bucket"
  bucket_name             = var.bucket_name # Set your S3 bucket name in terraform.tfvars
  versioning_status       = "Disabled"
  lifecycle_status        = "Disabled"
  expiration_days         = 30
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  ec2_iam_role_arn        = module.iam_ec2.ec2_iam_role_arn
  avatar_prefix           = "avatars/"
  avatar_filename         = "user_default.png"
  avatar_path             = "../backend/avatar/user_default.png"
  lambda_iam_role_arn     = module.iam_lambda.lambda_iam_role_arn
  db_dump_prefix          = "db_backups/"
  db_dump_filename        = "sqlite_dump_clean.sql"
  db_dump_path            = "../backend/app/sqlite_dump_clean.sql"
  layer_prefix          = "lambda_layers/"
  layer_filename        = "boto3-psycopg2-layer.zip"
  layer_path            = "lambda_data/boto3-psycopg2-layer.zip"
}

