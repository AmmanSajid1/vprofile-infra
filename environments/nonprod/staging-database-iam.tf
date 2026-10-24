data "aws_secretsmanager_secret" "staging_mysql_app" {
  name = "vprofile/staging/mysql-app"
}

data "aws_secretsmanager_secret" "staging_mysql_migrator" {
  name = "vprofile/staging/mysql-migrator"
}

resource "aws_iam_policy" "staging_mysql_bootstrap" {
  name = "vprofile-staging-mysql-bootstrap"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          module.staging_rds.master_user_secret_arn,
          data.aws_secretsmanager_secret.staging_mysql_app.arn,
          data.aws_secretsmanager_secret.staging_mysql_migrator.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = [
          aws_ssm_parameter.staging_rds_endpoint.arn,
          aws_ssm_parameter.staging_rds_master_secret_arn.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "staging_mysql_bootstrap" {
  name = "vprofile-staging-mysql-bootstrap-role"

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

resource "aws_iam_role_policy_attachment" "staging_mysql_bootstrap" {
  role       = aws_iam_role.staging_mysql_bootstrap.name
  policy_arn = aws_iam_policy.staging_mysql_bootstrap.arn
}

resource "aws_eks_pod_identity_association" "staging_mysql_bootstrap" {
  cluster_name    = module.eks.cluster_name
  namespace       = "staging"
  service_account = "vprofile-mysql-bootstrap"
  role_arn        = aws_iam_role.staging_mysql_bootstrap.arn

  depends_on = [
    aws_iam_role_policy_attachment.staging_mysql_bootstrap,
    module.eks
  ]
}

resource "aws_iam_policy" "staging_flyway" {
  name = "vprofile-staging-flyway"

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
          data.aws_secretsmanager_secret.staging_mysql_migrator.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = [
          aws_ssm_parameter.staging_rds_endpoint.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "staging_flyway" {
  name = "vprofile-staging-flyway-role"

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

resource "aws_iam_role_policy_attachment" "staging_flyway" {
  role       = aws_iam_role.staging_flyway.name
  policy_arn = aws_iam_policy.staging_flyway.arn
}

resource "aws_eks_pod_identity_association" "staging_flyway" {
  cluster_name    = module.eks.cluster_name
  namespace       = "staging"
  service_account = "vprofile-flyway"
  role_arn        = aws_iam_role.staging_flyway.arn

  depends_on = [
    aws_iam_role_policy_attachment.staging_flyway,
    module.eks
  ]
}
