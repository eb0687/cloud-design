resource "aws_cloudwatch_log_group" "application" {
  name              = "/${local.name}/application"
  retention_in_days = 7
}

resource "aws_cloudwatch_metric_alarm" "gateway_5xx" {
  alarm_name          = "${local.name}-gateway-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.gateway.arn_suffix
    TargetGroup  = aws_lb_target_group.gateway.arn_suffix
  }
}
