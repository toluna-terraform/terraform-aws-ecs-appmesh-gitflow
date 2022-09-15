resource "aws_sqs_queue" "merge_waiter_queue" {
  name                      = "${local.app_name}_${local.env_name}_merge_waiter_queue"

  delay_seconds             = 30
  max_message_size          = 2048
  message_retention_seconds = 7200
  receive_wait_time_seconds = 5
  # redrive_policy = jsonencode({
  #   deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
  #   maxReceiveCount     = 1
  # })

  tags = {
    Environment = "${local.app_name}-${local.env_name}"
  }
}