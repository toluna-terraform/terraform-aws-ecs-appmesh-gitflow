# ---- iam role for Lambdas
resource "aws_iam_role" "iam_for_lambda" {
  name = "lambda-role-${local.app_name}-${local.env_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "inline_policy_lambda_role" {
  name   = "inline-policy-${var.app_name}-${var.env_name}-lambda-role"
  role   = aws_iam_role.iam_for_lambda.id
  policy = data.aws_iam_policy_document.inline-policy-lambda-role-doc.json
}

# Attach App mesh access
# resource "aws_iam_policy_attachment" "attach-appmesh-policy" {
#   name       = "attach-appmesh-policy"
#   roles      = [ aws_iam_role.iam_for_lambda.name ]
#   policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshFullAccess"
# }

# Attach ECS access
# resource "aws_iam_policy_attachment" "attach-ecs-policy" {
#   name       = "attach-ecs-policy"
#   roles      = [ aws_iam_role.iam_for_lambda.name ]
#   policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
# }

# # Attach SSM access
# resource "aws_iam_policy_attachment" "attach-ssm-policy" {
#   name       = "attach-ssm-policy"
#   roles      = [ aws_iam_role.iam_for_lambda.name ]
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
# }

# # Attach SF access
# resource "aws_iam_policy_attachment" "attach-sf-policy" {
#   name       = "attach-sf-policy"
#   roles      = [ aws_iam_role.iam_for_lambda.name ]
#   policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
# }

