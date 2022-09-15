# --- lamda layer contains python modules of consul, etc
resource "aws_lambda_layer_version" "ecs_appmesh_pipeline_layer" {
  filename   = "${path.module}/lambdas/ecs_appmesh_pipeline_layer.zip"
  layer_name = "ecs_appmesh_pipeline_layer"

  compatible_runtimes = ["python3.9"]
}

# ---- deploying updated ECS service version in next color

data "archive_file" "deploy_updated_version_zip" {
    type        = "zip"
    source_file  = "${path.module}/lambdas/deploy_updated_version.py"
    output_path = "${path.module}/lambdas/deploy_updated_version.zip"
}

resource "aws_lambda_function" "deploy_updated_version" {
  runtime = "python3.9"
  function_name = "${var.app_name}-${var.env_name}-deploy_updated_version"

  description = "Changes ECS service between blue and green "
  filename = "${path.module}/lambdas/deploy_updated_version.zip"
  layers = [ aws_lambda_layer_version.ecs_appmesh_pipeline_layer.arn ]

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "deploy_updated_version.lambda_handler"

  environment {
    variables = {
      APP_NAME = var.app_name
      ENV_NAME = var.env_name
    }
  }
}

# ---- cleanup in case if tests fails in new env
# this part of the process to stay on old env
data "archive_file" "cleanup_zip" {
    type        = "zip"
    source_file  = "${path.module}/lambdas/cleanup.py"
    output_path = "${path.module}/lambdas/cleanup.zip"
}

resource "aws_lambda_function" "cleanup" {
  runtime = "python3.9"

  function_name = "${var.app_name}-${var.env_name}-cleanup"
  description = "cleanup services on applicatin nextColor service "
  filename = "${path.module}/lambdas/cleanup.zip"

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "cleanup.lambda_handler"

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
  runtime = "python3.9"

  function_name = "${var.app_name}-${var.env_name}-run_integration_tests"
  description = "Run Integration tests on nextColor service of application to decide if traffic can be switched."
  filename = "${path.module}/lambdas/run_integration_tests.zip"

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "run_integration_tests.lambda_handler"

  environment {
    variables = {
      APP_NAME = var.app_name
      ENV_NAME = var.env_name
      ENV_TYPE = var.env_type
      RUN_INTEGRATION_TESTS = var.run_integration_tests
      URL = "https://qa.buffet-non-prod.toluna-internal.com/${var.app_name}/${var.env_name}"
    }
  }

}

# ---- run_stress_tests

data "archive_file" "run_stress_tests_zip" {
    type        = "zip"
    source_file  = "${path.module}/lambdas/run_stress_tests.py"
    output_path = "${path.module}/lambdas/run_stress_tests.zip"
}

resource "aws_lambda_function" "run_stress_tests" {
  runtime = "python3.9"

  function_name = "${var.app_name}-${var.env_name}-run_stress_tests"
  description = "Run Stress tests on nextColor service of application to decide if traffic can be switched."
  filename = "${path.module}/lambdas/run_stress_tests.zip"

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "run_stress_tests.lambda_handler"

  environment {
    variables = {
      APP_NAME = var.app_name
      ENV_NAME = var.env_name
      ENV_TYPE = var.env_type
      RUN_STRESS_TESTS = var.run_stress_tests
      URL = "https://qa.buffet-non-prod.toluna-internal.com/${var.app_name}/${var.env_name}"
    }
  }

}

# ---- shifting traffic
data "archive_file" "shift_traffic_zip" {
    type        = "zip"
    source_file  = "${path.module}/lambdas/shift_traffic.py"
    output_path = "${path.module}/lambdas/shift_traffic.zip"
}

resource "aws_lambda_function" "shift_traffic" {
  runtime = "python3.9"

  function_name = "${var.app_name}-${var.env_name}-shift_traffic"
  description = "Changes traffic between blue and green by switching route weight"
  filename = "${path.module}/lambdas/shift_traffic.zip"
  layers = [ aws_lambda_layer_version.ecs_appmesh_pipeline_layer.arn ]

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


