resource "aws_iam_policy" "mysql_bootstrap" {
  name        = "vprofile-nonprod-mysql-bootstrap"
  description = "Allow database bootstrap to retrieve required credentials"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          module.rds.master_user_secret_arn,
          data.aws_secretsmanager_secret.mysql_app.arn,
          data.aws_secretsmanager_secret.mysql_migrator.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = [
          aws_ssm_parameter.rds_endpoint.arn,
          aws_ssm_parameter.rds_master_secret_arn.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "mysql_bootstrap" {
  name = "vprofile-nonprod-mysql-bootstrap-role"

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

resource "aws_iam_role_policy_attachment" "mysql_bootstrap" {
  role       = aws_iam_role.mysql_bootstrap.name
  policy_arn = aws_iam_policy.mysql_bootstrap.arn
}

resource "aws_eks_pod_identity_association" "mysql_bootstrap" {
  cluster_name    = module.eks.cluster_name
  namespace       = "dev"
  service_account = "vprofile-mysql-bootstrap"
  role_arn        = aws_iam_role.mysql_bootstrap.arn

  depends_on = [
    aws_iam_role_policy_attachment.mysql_bootstrap,
    module.eks
  ]
}