resource "aws_iam_policy" "external_secrets" {
  name        = "vprofile-nonprod-external-secrets"
  description = "Allow ESO to read vProfile nonprod application secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:us-east-1:464209272334:secret:rds!db-17567b02-fbb1-4b10-a3dd-e646753b276e-HG8KXr",
          "arn:aws:secretsmanager:us-east-1:464209272334:secret:vprofile/nonprod/rabbitmq-gs9l2P"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "external_secrets" {
  name = "vprofile-nonprod-external-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  role       = aws_iam_role.external_secrets.name
  policy_arn = aws_iam_policy.external_secrets.arn
}


resource "aws_eks_pod_identity_association" "external_secrets" {
  cluster_name    = module.eks.cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  role_arn        = aws_iam_role.external_secrets.arn
}