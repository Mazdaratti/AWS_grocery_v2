output "s3_bucket_name" {
  value = aws_s3_bucket.grocery_s3.bucket
  description = "The name of the S3 bucket"
}

output "s3_bucket_id" {
  description = "ID of the created S3 bucket"
  value       = aws_s3_bucket.grocery_s3.id
}

output "s3_bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.grocery_s3.arn
}

output "db_dump_s3_key" {
  description = "S3 key (path) of the uploaded database dump"
  value       = aws_s3_object.db_dump.key
}