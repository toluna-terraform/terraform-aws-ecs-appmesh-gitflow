# ---- copy merge-waiter py code to s3
resource "aws_s3_object" "merge_waiter_proj" {
  bucket = "s3-${local.app_name}-${local.env_type}"
  key    = "${local.app_name}-${local.env_name}"
  source = "${path.module}/merge-waiter.py"
}

# ---- copy merge-waiter buildspec to s3
resource "aws_s3_object" "merge_waiter_buildspec" {
  bucket = "s3-${local.app_name}-${local.env_type}"
  key    = "${local.app_name}-${local.env_name}"
  source = "${path.module}/merge-waiter-buildspec.yml"
}