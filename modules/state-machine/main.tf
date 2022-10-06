locals {
  app_name = var.app_name
  env_name = var.env_name
  env_type = var.env_type
  pipeline_branch = var.pipeline_branch
  next_color = (var.current_color == "green") ? "blue" : "green"
  aws_account_id = data.aws_caller_identity.current.account_id
}

# ---- create Step Function Orchestration flow
resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "${var.app_name}-${var.env_name}-state-machine"
  role_arn = aws_iam_role.iam_for_sfn.arn

  definition = <<EOF
{
  "Comment": "ECS gitflow with appmesh using an AWS Lambda Function",
  "StartAt": "deploy_updated_version",
  "States": {
    "deploy_updated_version": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.deploy_updated_version.arn}",
      "Next": "run_integration_tests"
    },
    "run_integration_tests": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.run_integration_tests.arn}",
      "InputPath": "$",
      "OutputPath": "$",
      "ResultPath": "$",
      "Parameters" : {
        "Url" : "https://${var.appmesh_name}.buffet-non-prod.toluna-internal.com/${var.env_name}/${var.app_name}"
      },
      "Next": "validate_integ_test_results"
    },
    "validate_integ_test_results": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.is_healthy",
          "StringEquals": "true",
          "Next": "run_stress_tests"
        },
        {  
          "Variable": "$.is_healthy",
          "StringEquals": "false",
          "Next": "CleanUp"
        }
      ]
    },
    "run_stress_tests": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.run_stress_tests.arn}",
      "InputPath": "$",
      "OutputPath": "$",
      "ResultPath": "$",
      "Parameters" : {
        "Url" : "https://${var.appmesh_name}.buffet-non-prod.toluna-internal.com/${var.env_name}/${var.app_name}"
      },
      "Next": "validate_stress_test_results"
    },
    "validate_stress_test_results": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.is_healthy",
          "StringEquals": "true",
          "Next": "Invoke-merge-waiter"
        },
        {  
          "Variable": "$.is_healthy",
          "StringEquals": "false",
          "Next": "CleanUp"
        }
      ]
    },
    "CleanUp": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.cleanup.arn}",
      "End": true
    },
    "Invoke-merge-waiter": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke.waitForTaskToken",
      "Parameters": {
        "Payload": {
          "DeploymentType" : "StepFunction" ,
          "DeploymentId" : "DeploymentId_001",
          "LifecycleEventHookExecutionId" : "LifecycleEventHookExecutionId_001", 
          "environment" : "${var.env_name}", 
          "taskToken.$": "$$.Task.Token"
        },
        "FunctionName": "chef-non-prod-merge-waiter",
      },
      "Next": "shift_traffic"
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



