data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github_oidc" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "oidc" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_oidc.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}@138880648/${var.github_repo}@1386408522:ref:refs/heads/main"
      ]
    }

  }
}

resource "aws_iam_role" "github_oidc_role" {
  name               = "vprofile-app-github-ci"
  assume_role_policy = data.aws_iam_policy_document.oidc.json
}

data "aws_iam_policy_document" "ecr_push" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:BatchGetImage",
    ]
    resources = ["arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repo_name}"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_push" {
  name        = "ci-ecr-push-policy"
  description = "Policy used for ECR push on CI"
  policy      = data.aws_iam_policy_document.ecr_push.json
}

resource "aws_iam_role_policy_attachment" "attach-ecr-push" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = aws_iam_policy.ecr_push.arn
}



