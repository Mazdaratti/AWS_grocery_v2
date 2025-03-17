output "bucket_name" {
  value = aws_s3_bucket.grocery_s3.bucket
  description = "The name of the S3 bucket"
}

output "bucket_id" {
  description = "ID of the created S3 bucket"
  value       = aws_s3_bucket.grocery_s3.id
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.grocery_s3.arn
}
