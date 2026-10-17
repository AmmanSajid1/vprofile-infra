resource "aws_iam_policy" "flyway" {
  name        = "vprofile-nonprod-flyway"
  description = "Allow Flyway to retrieve its MySQL migration credentials"

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
          data.aws_secretsmanager_secret.mysql_migrator.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = [
          aws_ssm_parameter.rds_endpoint.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "flyway" {
  name = "vprofile-nonprod-flyway-role"

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

resource "aws_iam_role_policy_attachment" "flyway" {
  role       = aws_iam_role.flyway.name
  policy_arn = aws_iam_policy.flyway.arn
}

resource "aws_eks_pod_identity_association" "flyway" {
  cluster_name    = module.eks.cluster_name
  namespace       = "dev"
  service_account = "vprofile-flyway"
  role_arn        = aws_iam_role.flyway.arn

  depends_on = [
    aws_iam_role_policy_attachment.flyway,
    module.eks
  ]
}