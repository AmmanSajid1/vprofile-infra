output "tfstate_bucket" {
  value = aws_s3_bucket.tfstate.id
}

output "tfstate_bucket_arn" {
  value = aws_s3_bucket.tfstate.arn
}