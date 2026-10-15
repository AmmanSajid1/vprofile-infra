output "vprofile_ecr_repository_url" {
  value = aws_ecr_repository.vprofile_ecr.repository_url
}


output "acm_certificate_arns" {
  description = "Validated ACM certificate ARNs by environment"
  value = {
    for env, validation in aws_acm_certificate_validation.cert_validation :
    env => validation.certificate_arn
  }
}
