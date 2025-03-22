resource "aws_s3_bucket" "grocery_s3" {
  bucket = var.bucket_name
  force_destroy = false
}

# Enable S3 to Send Events to EventBridge
resource "aws_s3_bucket_notification" "s3_to_eventbridge" {
  bucket = aws_s3_bucket.grocery_s3.id

  # Enable EventBridge notifications
  eventbridge = true
}

resource "aws_s3_bucket_versioning" "grocery_s3_versioning" {
  bucket = aws_s3_bucket.grocery_s3.id
  versioning_configuration {
    status = var.versioning_status
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "grocery_s3_lifecycle" {
  bucket = aws_s3_bucket.grocery_s3.id

  rule {
    id     = "expire-old-avatars"
    status = var.lifecycle_status

    filter {
      prefix = var.avatar_prefix
    }

    expiration {
      days = var.expiration_days
    }
  }
}

resource "aws_s3_bucket_public_access_block" "grocery_s3_block" {
  bucket = aws_s3_bucket.grocery_s3.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

resource "aws_s3_bucket_policy" "grocery_s3_policy" {
  bucket = aws_s3_bucket.grocery_s3.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow EC2 to access specific folders in S3
      {
        Sid       = "AllowEC2Access"
        Effect    = "Allow"
        Principal = {
          AWS = var.ec2_iam_role_arn # Allow the EC2 role
        }
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.grocery_s3.arn
      },
      {
        Sid       = "AllowEC2ObjectAccess"
        Effect    = "Allow"
        Principal = {
          AWS = var.ec2_iam_role_arn # Allow the EC2 role
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.grocery_s3.arn}/${var.avatar_prefix}*"
      },

      # Allow Lambda to access specific folders in S3
      {
        Sid       = "AllowLambdaAccess"
        Effect    = "Allow"
        Principal = {
          AWS = var.lambda_iam_role_arn # Allow the Lambda function role
        }
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.grocery_s3.arn
      },
      {
        Sid       = "AllowLambdaObjectAccess"
        Effect    = "Allow"
        Principal = {
          AWS = var.lambda_iam_role_arn # Allow the Lambda function role
        }
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.grocery_s3.arn}/${var.db_dump_prefix}*"
      }
    ]
  })
}

resource "aws_s3_object" "avatar_image" {
  bucket = aws_s3_bucket.grocery_s3.id
  key    = "${var.avatar_prefix}${var.avatar_filename}"
  source = var.avatar_path
}

resource "aws_s3_object" "layer_image" {
  bucket = aws_s3_bucket.grocery_s3.id
  key    = "${var.layer_prefix}${var.layer_filename}"
  source = var.layer_path
}