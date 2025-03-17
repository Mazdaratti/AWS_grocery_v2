# Security Groups
resource "aws_security_group" "alb_sg" {
  vpc_id = var.vpc_id
  name   = "alb-sg"
  description = "Security group for Load Balancer"

  dynamic "ingress" {
    for_each    = var.alb_ingress_ports
    content {
      from_port = ingress.value
      to_port   = ingress.value
      protocol  = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_sg" {
  vpc_id = var.vpc_id
  name   = "ec2-sg"
  description = "Security group for EC2 instances"

  ingress {
    from_port   = var.ec2_ingress_ports[0]
    to_port     = var.ec2_ingress_ports[0]
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description = "Allow HTTP access from ALB to EC2"
  }

  ingress {
    from_port = var.ec2_ingress_ports[1]
    to_port   = var.ec2_ingress_ports[1]
    protocol  = "tcp"
    cidr_blocks = [var.allowed_ssh_ip]
    description = "Allow SSH access from specific IP"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  vpc_id = var.vpc_id
  name   = "rds-sg"
  description = "Security group for RDS instances"

  ingress {
    from_port   = var.rds_port
    to_port     = var.rds_port
    protocol    = "tcp"
    security_groups = [aws_security_group.ec2_sg.id,aws_security_group.lambda_sg.id]
    description     = "Allow access from EC2 instances and Lambda"
  }
}

# Security Group for Lambda
resource "aws_security_group" "lambda_sg" {
  name        = "lambda-sg"
  description = "Allow Lambda to connect to RDS and S3"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow outbound traffic to RDS and S3
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "lambda-sg"
  }
}