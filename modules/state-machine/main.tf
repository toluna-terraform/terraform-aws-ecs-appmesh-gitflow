locals {
  app_name = var.app_name
  env_name = var.env_name
  # suffix = $
  env_type = var.env_type
  pipeline_branch = var.pipeline_branch
  next_color = (var.current_color == "green") ? "blue" : "green"
  aws_account_id = data.aws_caller_identity.current.account_id
  appmesh_profile = var.appmesh_profile
  appmesh_name = var.appmesh_name
}

# ---- create Step Function Orchestration flow
resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "${var.app_name}-${var.env_name}-state-machine"
  role_arn = aws_iam_role.iam_for_sfn.arn

  definition = <<EOF
{
  "Comment": "Blue-Green deployment orchestration with appmesh routes",
  "StartAt": "deploy_updated_version",
  "States": {
    "deploy_updated_version": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.deploy_updated_version.arn}",
      "Next": "run_integ_and_stress_tests"
    },
    "run_integ_and_stress_tests": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke.waitForTaskToken",
      "Parameters": {
        "FunctionName": "${var.app_name}-${var.env_type}-test-framework-manager",
        "Payload": {
          "DeploymentType" : "AppMesh" ,
          "Combined" : false,
          "IntegResults": false,
          "StressResults": false,
          "environment" : "${var.env_name}", 
          "trigger": "${local.app_name}-${local.env_name}-state-machine",
          "lb_name": "${local.apapmesh_name}.${local.appmesh_profile}.toluna-internal.com",
          "integration_report_group": "arn:aws:codebuild:us-east-1:${local.aws_account_id}:report-group/${local.app_name}-${local.env_name}-IntegrationTestReport",
          "stress_report_group": "arn:aws:codebuild:us-east-1:${local.aws_account_id}:report-group/${local.app_name}-${local.env_name}-StressTestReport",
          "taskToken.$": "$$.Task.Token"
        }
      },
      "Next": "validate_test_results"
    },
    "validate_test_results": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.StatusCode",
          "StringEquals": "200",
          "Next": "notify_merge_readiness_in_PR"
        },
        {  
          "Variable": "$.StatusCode",
          "StringEquals": "400",
          "Next": "CleanUp"
        }
      ]
    },
    "CleanUp": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.cleanup.arn}",
      "End": true
    },
    "notify_merge_readiness_in_PR": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke.waitForTaskToken",
      "Parameters": {
        "FunctionName": "${var.app_name}-${var.env_type}-merge-waiter",
        "Payload": {
          "DeploymentType" : "AppMesh" ,
          "DeploymentId" : "Dummy_DeploymentId",
          "LifecycleEventHookExecutionId" : "Dummy_LifecycleEventHookExecutionId", 
          "environment" : "${var.env_name}", 
          "taskToken.$": "$$.Task.Token"
        }
      },
      "Next": "pass_sf_token_and_wait_for_merge"
    },
    "pass_sf_token_and_wait_for_merge": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke.waitForTaskToken",
      "Parameters": {
        "FunctionName": "${var.app_name}-${var.env_type}-appmesh-task-token",
        "Payload": {
          "DeploymentType" : "AppMesh" ,
          "CallerId" : "StepFunction",
          "environment" : "${var.env_name}", 
          "TaskToken.$": "$$.Task.Token"
        }
      },
      "Next": "is_merged"
    },
    "is_merged": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.StatusCode",
          "StringEquals": "200",
          "Next": "shift_traffic"
        },
        {  
          "Variable": "$.StatusCode",
          "StringEquals": "400",
          "Next": "CleanUp"
        }
      ]
    },
    "shift_traffic": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.shift_traffic.arn}",
      "End": true
    }
  }
}
EOF
}



