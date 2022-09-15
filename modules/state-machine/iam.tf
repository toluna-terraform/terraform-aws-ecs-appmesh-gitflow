# ---- iam role for Lambdas
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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

# Attach inline policy to access SQS, CloudWatch, etc
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
            "Resource": "arn:aws:lambda:*:603106382807:function:*"
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
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "sqs:*"
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

# ---- IAM role for Step function
resource "aws_iam_role" "iam_for_sfn" {
  name = "iam_for_sfn"
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
  name = "InlinePolicyForSQSAccess4SF"
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
            "Resource": "arn:aws:lambda:*:603106382807:function:*"
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
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "sqs:*"
            ],
            "Resource": "*"
        }
    ]
})
}

# -------- iam role for merge waiter
resource "aws_iam_role" "merge_waiter_role" {
  name = "${local.app_name}-${local.env_name}-role-merge-waiter"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "merge_waiter_policy" {
  role = aws_iam_role.merge_waiter_role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::s3-${local.app_name}-${local.env_type}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "attach_sf_access" {
  name       = "${local.app_name}-${local.env_name}-attach_sf_access"

  roles      = [ "${aws_iam_role.merge_waiter_role.name}" ]
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
}

resource "aws_iam_policy_attachment" "attach_sqs_access" {
  name       = "${local.app_name}-${local.env_name}-attach_sqs_access"

  roles      = [ "${aws_iam_role.merge_waiter_role.name}" ]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSReadOnlyAccess"
}



