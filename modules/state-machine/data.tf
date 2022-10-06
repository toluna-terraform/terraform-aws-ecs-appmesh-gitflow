data "consul_keys" "current_color" {
  key {
    name    = "current_color"
    path    = "infra/${var.app_name}-${var.env_name}/current_color"
  }
}

data "template_file" "merge_waiter_py" {
  template = "${file("${path.module}/merge-waiter.py.tpl")}"
  vars = {
    APP_NAME = var.app_name,
    ENV_NAME = var.env_name
  }
}

data "aws_caller_identity" "current" {}