// CloudWatch group and log stream; retain logs for 30 days
resource "aws_cloudwatch_log_group" "logs" {
  name              = "/ecs/${var.PROJECT}/${var.ENV}"
  retention_in_days = 30

  tags = {
    Name = var.PROJECT
    Env = var.ENV
  }
}

resource "aws_cloudwatch_log_stream" "log_stream" {
  name           = "${var.PROJECT}-${var.ENV}"
  log_group_name = aws_cloudwatch_log_group.logs.name
}