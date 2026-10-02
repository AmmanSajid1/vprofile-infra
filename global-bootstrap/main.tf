data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "tfstate" {
  bucket = "vprofile-tfstate-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true
  }
}

# Versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "tfstate_versioning" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server side encryption for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_encryption" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "tfstate_public_access_block" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# HTTPS enforcement for the S3 bucket
data "aws_iam_policy_document" "enforce_https" {
  statement {
    sid    = "EnforceHTTPS"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = ["${aws_s3_bucket.tfstate.arn}/*", "${aws_s3_bucket.tfstate.arn}"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "tfstate_https_enforcement" {
  bucket = aws_s3_bucket.tfstate.id
  policy = data.aws_iam_policy_document.enforce_https.json
}

