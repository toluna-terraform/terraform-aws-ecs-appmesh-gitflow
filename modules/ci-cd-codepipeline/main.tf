locals {
  app_name = var.app_name
  env_name = var.env_name
  codepipeline_name     = "codepipeline-${local.app_name}-${local.env_name}"
  aws_account_id = data.aws_caller_identity.current.account_id
}

resource "aws_codepipeline" "codepipeline" {
  name     = local.codepipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = var.s3_bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Download_Merged_Sources"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket = "${var.s3_bucket}"
        S3ObjectKey = "${var.env_name}/source_artifacts.zip" 
        PollForSourceChanges = true
      }
    }
  }


  stage {
    name = "CI"
    dynamic "action" {
      for_each = var.build_codebuild_projects
      content {
        name             = action.value
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["source_output"]
        version          = "1"
        output_artifacts = ["ci_output"]

        configuration = {
          ProjectName = action.value
        }

      }

    }
  }

  stage {
    name = "Pre-Deploy"
    dynamic "action" {
      for_each = var.pre_codebuild_projects
      content {
        name             = action.value
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["ci_output"]
        version          = "1"
        output_artifacts = var.pipeline_type == "dev" ? ["dev_output"] : ["cd_output"]

        configuration = {
          ProjectName = action.value
        }

      }

    }
  }


  stage {
    name = "${var.app_name}-${var.env_name}-StateMachine"
    dynamic "action" {
      for_each = var.code_deploy_applications
      content {
        name            = action.value
        category        = "Invoke"
        owner           = "AWS"
        provider        = "StepFunctions"
        version         = "1"

        configuration = {
          # StateMachineArn = resource.aws_sfn_state_machine.sfn_state_machine.arn
          StateMachineArn = "arn:aws:states:us-east-1:${local.aws_account_id}:stateMachine:${local.app_name}-${local.env_name}-state-machine"
          InputType = "Literal"
          Input = "{ \"input\": { \"name\": \"Srinivas\" },  \"output\": {  \"health_state\": \"healthy\"  }, \"results\": {  \"result1\": \"200 - ok\" }  }"

        }
      }
    }
  }

    stage {
    name = "Post-Deploy"
    dynamic "action" {
      for_each = var.post_codebuild_projects
      content {
        name             = action.value
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["source_output"]
        version          = "1"

        configuration = {
          ProjectName = action.value
        }

      }

    }
  }

}



