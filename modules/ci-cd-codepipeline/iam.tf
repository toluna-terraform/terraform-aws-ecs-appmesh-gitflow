resource "aws_iam_role" "codepipeline_role" {
  name               = "role-${local.codepipeline_name}"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role_policy.json
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "policy-${local.codepipeline_name}"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_role_policy.json
}

# Attach policy to execute StateMachine to code pipeline role
resource "aws_iam_policy_attachment" "attach-sf-policy" {
  name       = "attach-sm-policy-${local.app_name}-${local.env_name}"
  roles      = [ aws_iam_role.codepipeline_role.name ]
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
}
