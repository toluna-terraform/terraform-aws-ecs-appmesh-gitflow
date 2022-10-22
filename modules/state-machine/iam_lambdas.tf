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

# Attach inline policy to access CloudWatch, etc
resource "aws_iam_role_policy" "InlinePolicyForSQSAccess" {
  name = "InlinePolicyForSQSAccess"
  role = aws_iam_role.iam_for_lambda.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": "lambda:InvokeFunction",
            "Resource": "arn:aws:lambda:*:${local.aws_account_id}:function:*"
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents",
                "logs:CreateLogStream",
                "logs:CreateLogGroup"
            ],
            "Resource": "*"
        }
    ]
})
}


# Attach App mesh access
resource "aws_iam_policy_attachment" "attach-appmesh-policy" {
  name       = "attach-appmesh-policy"
  roles      = [ aws_iam_role.iam_for_lambda.name ]
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshFullAccess"
}

# Attach ECS access
resource "aws_iam_policy_attachment" "attach-ecs-policy" {
  name       = "attach-ecs-policy"
  roles      = [ aws_iam_role.iam_for_lambda.name ]
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

# Attach SSM access
resource "aws_iam_policy_attachment" "attach-ssm-policy" {
  name       = "attach-ssm-policy"
  roles      = [ aws_iam_role.iam_for_lambda.name ]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

