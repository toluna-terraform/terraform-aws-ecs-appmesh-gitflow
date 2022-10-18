# ---- IAM role for Step function
resource "aws_iam_role" "iam_for_sfn" {
  name = "sf-role-${local.app_name}-${local.env_name}"
  managed_policy_arns = [ "arn:aws:iam::aws:policy/service-role/AWSLambdaRole" ]

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
              "Service": "states.amazonaws.com"
            },
           "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

# ---- Attach inline policy to access SQS, CloudWatch, etc
resource "aws_iam_role_policy" "InlinePolicyForSQSAccess4SF" {
  name = "InlinePolicyForSF"
  role = aws_iam_role.iam_for_sfn.id

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
