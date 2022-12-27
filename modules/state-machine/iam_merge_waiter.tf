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
    },
    {
        "Effect": "Allow",
        "Action": [
            "states:*"
        ],
        "Resource": [
            "arn:aws:states:us-east-1:${local.aws_account_id}:stateMachine:${local.app_name}-${local.env_name}-state-machine"
        ]
    },  
    {
        "Effect": "Allow",
        "Action": [
            "sqs:*"
        ],
        "Resource": [
            "arn:aws:sqs:us-east-1:${local.aws_account_id}:${local.app_name}_${local.env_name}_merge_waiter_queue"
        ]
    }
  ]
}
POLICY
}

# resource "aws_iam_policy_attachment" "attach_sf_access" {
#   name       = "${local.app_name}-${local.env_name}-attach_sf_access"

#   roles      = [ "${aws_iam_role.merge_waiter_role.name}" ]
#   policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
# }

# resource "aws_iam_policy_attachment" "attach_sqs_access" {
#   name       = "${local.app_name}-${local.env_name}-attach_sqs_access"

#   roles      = [ "${aws_iam_role.merge_waiter_role.name}" ]
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
# }