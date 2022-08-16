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
      "Next": "validate_integ_test_results"
    },
    "validate_integ_test_results": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.is_healthy",
          "StringEquals": "true",
          "Next": "wait_for_merge"
        },
        {  
          "Variable": "$.is_healthhy",
          "StringEquals": "false",
          "Next": "rollback"
        }
      ],
      "Default": "wait_for_merge"
    },
    "rollback": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.rollback.arn}",
      "End": true
    },
    "wait_for_merge": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.wait_for_merge.arn}",
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


