data "consul_keys" "current_color" {
  key {
    name    = "current_color"
    path    = "infra/${var.app_name}-${var.env_name}/current_color"
  }
}

data "aws_ssm_parameter" "merge_timeout_seconds" {
    name    = "/infra/${var.app_name}-${env_name}/merge_timeout_seconds"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "inline-policy-lambda-role-doc" {
  statement {
    actions = [
      "ssm:*"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "states:*"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecs:*"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "iam:PassRole"
    ]
    resources = ["arn:aws:iam::*:role/role-ecs-${var.app_name}-${var.env_name}"]
  }
  statement {
    actions   = ["iam:PassRole"]
    resources = ["*"]
    condition {
      test = "StringEqualsIfExists"
      variable = "iam:PassedToService"
      values = ["ecs-tasks.amazonaws.com"]
    }
  }
  statement {
    actions = [
      "appmesh:*"
    ]
    resources = ["*"]
  }
}