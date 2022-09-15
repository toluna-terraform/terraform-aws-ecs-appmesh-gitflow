# ---- copy merge-waiter py code to s3
resource "aws_s3_object" "merge_waiter_proj" {
  bucket = "s3-${local.app_name}-${local.env_type}"
  key    = "${local.app_name}-${local.env_name}-merge-waiter.py"
  content = templatefile( "${path.module}/merge-waiter.py.tpl", 
    {
      APP_NAME = "\"${var.app_name}\"",
      ENV_NAME = "\"${var.env_name}\""
    }
  )
}

# ---- copy merge-waiter buildspec to s3
resource "aws_s3_object" "merge_waiter_buildspec" {
  bucket = "s3-${local.app_name}-${local.env_type}"
  key    = "${local.app_name}-${local.env_name}-buildspec.yml"
  source = "${path.module}/merge-waiter-buildspec.yml"
}