# ---- deploying updated ECS service version in next color

data "archive_file" "deploy_updated_version_zip" {
    type        = "zip"
    source_file  = "${path.module}/lambdas/deploy_updated_version.py"
    output_path = "${path.module}/lambdas/deploy_updated_version.zip"
}

resource "aws_lambda_function" "deploy_updated_version" {
  runtime = "python3.8"

  function_name = "deploy_updated_version"
  description = "Changes ECS service between blue and green "
  filename = "${path.module}/lambdas/deploy_updated_version.zip"

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "deploy_updated_version.lambda_handler"

  environment {
    variables = {
      APP_NAME = var.app_name
      ENV_NAME = var.env_name
    }
  }
}

# ---- cleanup in case if tests fails
data "archive_file" "rollback_zip" {
    type        = "zip"
    source_file  = "${path.module}/lambdas/rollback.py"
    output_path = "${path.module}/lambdas/rollback.zip"
}

resource "aws_lambda_function" "rollback" {
  runtime = "python3.8"

  function_name = "rollback"
  description = "Rollback services on applicatin nextColor service "
  filename = "${path.module}/lambdas/rollback.zip"

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "rollback.lambda_handler"

  environment {
    variables = {
      APP_NAME = var.app_name
      ENV_NAME = var.env_name
    }
  }
}

# ---- run_integration_tests

data "archive_file" "run_integration_tests_zip" {
    type        = "zip"
    source_file  = "${path.module}/lambdas/run_integration_tests.py"
    output_path = "${path.module}/lambdas/run_integration_tests.zip"
}

resource "aws_lambda_function" "run_integration_tests" {
  runtime = "python3.8"

  function_name = "run_integration_tests"
  description = "Run Integration tests on nextColor service of application to decide if traffic can be switched."
  filename = "${path.module}/lambdas/run_integration_tests.zip"

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "run_integration_tests.lambda_handler"

  environment {
    variables = {
      APP_NAME = var.app_name
      ENV_NAME = var.env_name
      URL = "https://qa.buffet-non-prod.toluna-internal.com/${var.app_name}/${var.env_name}"
    }
  }

}

# ---- wait for merge interrupt from controller

data "archive_file" "wait_for_merge_zip" {
    type        = "zip"
    source_file  = "${path.module}/lambdas/wait_for_merge.py"
    output_path = "${path.module}/lambdas/wait_for_merge.zip"
}

resource "aws_lambda_function" "wait_for_merge" {
  runtime = "python3.8"

  function_name = "wait_for_merge"
  description = "Changes ECS service between blue and green "
  filename = "${path.module}/lambdas/wait_for_merge.zip"

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "wait_for_merge.lambda_handler"
}

# ---- shifting traffic
data "archive_file" "shift_traffic_zip" {
    type        = "zip"
    source_file  = "${path.module}/lambdas/shift_traffic.py"
    output_path = "${path.module}/lambdas/shift_traffic.zip"
}

resource "aws_lambda_function" "shift_traffic" {
  runtime = "python3.8"

  function_name = "shift_traffic"
  description = "Changes traffic between blue and green by switching route weight"
  filename = "${path.module}/lambdas/shift_traffic.zip"

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "shift_traffic.lambda_handler"

  environment {
    variables = {
      APP_NAME = var.app_name
      ENV_NAME = var.env_name
      MESH_OWNER = var.appmesh_owner
      MESH_NAME = var.appmesh_name
    }
  }
}


