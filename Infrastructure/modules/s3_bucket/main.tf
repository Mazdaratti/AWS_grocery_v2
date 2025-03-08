resource "aws_s3_bucket" "grocery_s3" {
  bucket = var.bucket_name
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
      {
        Sid       = "AllowEC2Access"
        Effect    = "Allow"
        Principal = {
          AWS = var.iam_role_arn # Allow the EC2 role
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.grocery_s3.arn}/${var.avatar_prefix}*",
          aws_s3_bucket.grocery_s3.arn
        ]
      },
      {
        Sid       = "AllowLambdaAccess"
        Effect    = "Allow"
        Principal = {
          AWS = var.lambda_role_arn # Allow the Lambda function role
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.grocery_s3.arn}/${var.db_dump_prefix}${var.db_dump_filename}",
          aws_s3_bucket.grocery_s3.arn
        ]
      }
    ]
  })
}

resource "aws_s3_object" "avatar_image" {
  bucket = aws_s3_bucket.grocery_s3.id
  key    = "${var.avatar_prefix}${var.avatar_filename}"
  source = var.avatar_path
}

resource "aws_s3_object" "db_dump" {
  bucket                 = aws_s3_bucket.grocery_s3.id
  key                    = "${var.db_dump_prefix}${var.db_dump_filename}"
  source                 = var.db_dump_path
  # Optional: Enable Server-Side Encryption
  server_side_encryption = "AES256"
}