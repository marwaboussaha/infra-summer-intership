resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = var.name
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "ALB - requêtes et erreurs"
          region = var.region
          stat   = "Sum"
          period = 300
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            [".", "HTTPCode_Target_5XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
          ]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "ECS - CPU par service"
          region = var.region
          stat   = "Average"
          period = 300
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.app_cluster_name, "ServiceName", var.backend_service_name],
            ["...", var.frontend_service_name],
          ]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title  = "DocumentDB"
          region = var.region
          stat   = "Average"
          period = 300
          metrics = [
            ["AWS/DocDB", "CPUUtilization", "DBClusterIdentifier", var.docdb_cluster_identifier],
            [".", "DatabaseConnections", ".", "."],
          ]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title  = "WAF - requêtes bloquées"
          region = var.region
          stat   = "Sum"
          period = 300
          metrics = [
            ["AWS/WAFV2", "BlockedRequests", "WebACL", var.waf_web_acl_name, "Region", var.region, "Rule", "ALL"],
          ]
        }
      },
    ]
  })
}
