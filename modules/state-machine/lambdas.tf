# --- python lamda layer contains python modules of consul, etc
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
  source_code_hash = filebase64sha256("${path.module}/lambdas/deploy_updated_version.zip")
  layers = [ aws_lambda_layer_version.ecs_appmesh_pipeline_layer.arn ]

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "deploy_updated_version.lambda_handler"

  environment {
    variables = {
      APP_NAME = var.app_name
      ENV_NAME = var.env_name
      ENV_TYPE = var.env_type
      MESH_NAME = var.appmesh_name
      MESH_OWNER = var.appmesh_owner
    }
  }

  timeout = 300
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
  description = "cleanup services on application nextColor service "

  filename = "${path.module}/lambdas/cleanup.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/cleanup.zip")
  layers = [ aws_lambda_layer_version.ecs_appmesh_pipeline_layer.arn ]

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "cleanup.lambda_handler"

  environment {
    variables = {
      APP_NAME = var.app_name
      ENV_NAME = var.env_name
      ENV_TYPE = var.env_type
    }
  }

  timeout = 180
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
  source_code_hash = filebase64sha256("${path.module}/lambdas/shift_traffic.zip")
  layers = [ aws_lambda_layer_version.ecs_appmesh_pipeline_layer.arn ]

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "shift_traffic.lambda_handler"

  environment {
    variables = {
      APP_NAME = var.app_name
      ENV_NAME = var.env_name
      ENV_TYPE = var.env_type
      MESH_OWNER = var.appmesh_owner
      MESH_NAME = var.appmesh_name
    }
  }

  timeout = 180
}

# --- python lamda layer contains python modules of consul, etc
resource "aws_lambda_layer_version" "appmesh_pipeline_nodejs_layer" {
  filename   = "${path.module}/lambdas/appmesh_pipeline_nodejs_layer.zip"
  layer_name = "appmesh_pipeline_pipeline_layer"

  compatible_runtimes = ["nodejs14.x"]
}

# ---- update consul key color to blue/green
data "archive_file" "update_consul_bg_color_zip" {
    type        = "zip"
    source_file  = "${path.module}/lambdas/update_consul_bg_color.js"
    output_path = "${path.module}/lambdas/update_consul_bg_color.zip"
}

resource "aws_lambda_function" "update_consul_bg_color" {
  runtime = "nodejs14.x"

  function_name = "${var.app_name}-${var.env_name}-update_consul_bg_color"
  description = "Update consul key value of current_color to blue/green"
  filename = "${path.module}/lambdas/update_consul_bg_color.zip"
  source_code_hash = filebase64sha256("${path.module}/lambdas/update_consul_bg_color.zip")
  layers = [ aws_lambda_layer_version.appmesh_pipeline_nodejs_layer.arn ]

  role = "${aws_iam_role.iam_for_lambda.arn}"
  handler = "update_consul_bg_color.handler"

  environment {
    variables = {
      APP_NAME = var.app_name
      ENV_NAME = var.env_name
      ENV_TYPE = var.env_type
    }
  }

  timeout = 60
}


