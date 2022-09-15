locals {
  next_color = (var.current_color == "green") ? "blue" : "green"
}

resource "aws_codedeploy_app" "codedeploy_app" {
  name = "ecs-deploy-${var.env_name}"
  compute_platform = "ECS"
  
}


# resource "aws_ecs_service" "app_next_color" {
#   name            = "${var.app_name}-${local.next_color}"
#   # name            = "${var.app_name}-yellow"
#   # cluster         = var.ecs_cluster_name

#   task_definition = "${var.app_name}-${var.env_name}-${local.next_color}"
#   launch_type     = "FARGATE"
#   desired_count   = 3
#   # iam_role        = aws_iam_role.codedeploy_role.arn
#   force_new_deployment  = true

#   network_configuration { 
#       subnets = [ "subnet-0da2b96b8d2599f5a", "subnet-01e235a2eecb01b13" ]
#       security_groups = [ "sg-0f17b290d66543c9d" ]
#       assign_public_ip = false 
#   }

#   depends_on      = [ aws_iam_role.codedeploy_role ]

# }

# resource "aws_codedeploy_deployment_group" "deployment_group" {
#   count = ( var.appmesh_pipeline == true) ? 1 : 0

#   app_name               = aws_codedeploy_app.codedeploy_app.name
#   deployment_group_name  = "ecs-deploy-group-${var.env_name}"
#   deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
#   service_role_arn       = aws_iam_role.codedeploy_role.arn

#   ecs_service {
#     cluster_name = var.ecs_cluster_name
#     service_name = var.ecs_service_name
#   }

#   deployment_style {
#     deployment_option = "WITH_TRAFFIC_CONTROL"
#     deployment_type   = "IN_PLACE"
#   }

#   auto_rollback_configuration {
#     enabled = true
#     events  = ["DEPLOYMENT_FAILURE"]
#   }


# }

# resource "aws_codedeploy_deployment_group" "deployment_group" {

#   app_name               = aws_codedeploy_app.codedeploy_app.name
#   deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
#   deployment_group_name  = "ecs-deploy-group-${var.env_name}"
#   service_role_arn       = aws_iam_role.codedeploy_role.arn

#   auto_rollback_configuration {
#     enabled = true
#     events  = ["DEPLOYMENT_FAILURE"]
#   }

# blue_green_deployment_config {
#   deployment_ready_option {
#     action_on_timeout = "CONTINUE_DEPLOYMENT"
#   }

#   terminate_blue_instances_on_deployment_success {
#     action                           = "TERMINATE"
#     termination_wait_time_in_minutes = var.termination_wait_time_in_minutes
#   }
# }

# deployment_style {
#   deployment_option = "WITH_TRAFFIC_CONTROL"
#   deployment_type   = "BLUE_GREEN"
# }

# ecs_service {
#   cluster_name = var.ecs_cluster_name
#   service_name = var.ecs_service_name
# }

#   load_balancer_info {
#     target_group_pair_info {
#       prod_traffic_route {
#         listener_arns = [var.alb_listener_arn]
#       }

#       test_traffic_route {
#         listener_arns = [var.alb_test_listener_arn]
#       }

#       target_group {
#         name = var.alb_tg_blue_name 
#       }

#       target_group {
#         name = var.alb_tg_green_name 
#       }
#     }
#   }
# }

resource "aws_iam_role" "codedeploy_role" {
  name = "role-codedeploy-${var.app_name}-${var.env_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "cloudWatch_policy" {
  name = "policy-cloudWatch_policy-${var.env_name}"
  role = aws_iam_role.codedeploy_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "ecs_policy" {
  name = "policy-ecs_policy-${var.env_name}"
  role = aws_iam_role.codedeploy_role.id
  policy = data.aws_iam_policy_document.codedeploy_role_policy.json
}

resource "aws_iam_role_policy_attachment" "role-lambda-execution" {
    role       = "${aws_iam_role.codedeploy_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}