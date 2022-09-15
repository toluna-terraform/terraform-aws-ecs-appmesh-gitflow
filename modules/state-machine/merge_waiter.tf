# ---- merge-watier CodeBuild project
resource "aws_codebuild_project" "merge_waiter" {
  name = "${local.app_name}-${local.env_name}-merge-waiter"
  description= "wait for git repo merge hook"

  build_timeout = "30"
  service_role = aws_iam_role.merge_waiter_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

  }
  source {
      type            = "BITBUCKET"
      location        = "https://bitbucket.org/tolunaengineering/${local.app_name}.git"
      git_clone_depth = 1

      # buildspec = "arn:aws:s3:::s3-${local.app_name}-${local.env_type}/${local.app_name}-${local.env_name}-buildspec.yml"
      buildspec = templatefile("${path.module}/merge-waiter-buildspec.yml.tpl", 
        {
          APP_NAME = local.app_name,
          ENV_NAME = local.env_name,
          ENV_TYPE = local.env_type
        }
      )
  }

  # source_version = "master"
  source_version = "trigger-appmesh-pipeline-br"

}

# ---- git webhook for merge-waiter codebuild
resource "aws_codebuild_webhook" "merge_waiter_hook" {
  project_name = aws_codebuild_project.merge_waiter.name
  build_type   = "BUILD"
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_MERGED"
    }

    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_CREATED"
    }
    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_UPDATED"
    }

    filter {
      type    = "HEAD_REF"
      # pattern = "master"
      pattern = "trigger-appmesh-pipeline-br"
    }
  }
}