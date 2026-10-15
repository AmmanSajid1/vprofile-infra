data "aws_route53_zone" "main" {
  name         = var.hosted_zone_name
  private_zone = false
}

# create an ACM certificate per environment
resource "aws_acm_certificate" "cert" {
  for_each                  = var.domain_map_env
  domain_name               = each.value[0]
  subject_alternative_names = slice(each.value, 1, length(each.value))
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Project     = var.project_name,
    Environment = each.key,
    ManagedBy   = "Terraform",
  }
}

# convert the certificate validation options into a flat list
locals {
  validation_records = flatten([
    for env, cert in aws_acm_certificate.cert : [
      for dvo in cert.domain_validation_options : {
        key    = "${env}-${dvo.domain_name}"
        env    = env
        name   = dvo.resource_record_name
        record = dvo.resource_record_value
        type   = dvo.resource_record_type
      }
    ]
  ])
}

# create DNS validation records for every certificate domain
resource "aws_route53_record" "cert_record" {
  for_each = {
    for item in local.validation_records : item.key => item
  }
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}

# wait for ACM to validate each certificate
resource "aws_acm_certificate_validation" "cert_validation" {
  for_each        = aws_acm_certificate.cert
  certificate_arn = each.value.arn

  validation_record_fqdns = [
    for key, record in aws_route53_record.cert_record :
    record.fqdn
    if startswith(key, "${each.key}-")
  ]
}
