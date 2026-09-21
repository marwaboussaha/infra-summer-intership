locals {
  alarms = {
    alb-5xx = {
      namespace  = "AWS/ApplicationELB"
      metric     = "HTTPCode_Target_5XX_Count"
      stat       = "Sum"
      threshold  = 20
      dimensions = { LoadBalancer = var.alb_arn_suffix }
    }
    backend-unhealthy = {
      namespace  = "AWS/ApplicationELB"
      metric     = "UnHealthyHostCount"
      stat       = "Maximum"
      threshold  = 0
      dimensions = { LoadBalancer = var.alb_arn_suffix, TargetGroup = var.backend_target_group_arn_suffix }
    }
    backend-cpu = {
      namespace  = "AWS/ECS"
      metric     = "CPUUtilization"
      stat       = "Average"
      threshold  = 85
      dimensions = { ClusterName = var.app_cluster_name, ServiceName = var.backend_service_name }
    }
    docdb-cpu = {
      namespace  = "AWS/DocDB"
      metric     = "CPUUtilization"
      stat       = "Average"
      threshold  = 80
      dimensions = { DBClusterIdentifier = var.docdb_cluster_identifier }
    }
    waf-blocked = {
      namespace  = "AWS/WAFV2"
      metric     = "BlockedRequests"
      stat       = "Sum"
      threshold  = 500
      dimensions = { WebACL = var.waf_web_acl_name, Region = var.region, Rule = "ALL" }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.alarms

  alarm_name          = "${var.name}-${each.key}"
  namespace           = each.value.namespace
  metric_name         = each.value.metric
  statistic           = each.value.stat
  dimensions          = each.value.dimensions
  period              = 300
  evaluation_periods  = 2
  threshold           = each.value.threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}
