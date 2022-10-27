data "consul_keys" "current_color" {
  key {
    name    = "current_color"
    path    = "infra/${var.app_name}-${var.env_name}/current_color"
  }
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
}