# Findings de sécurité -> SNS
resource "aws_cloudwatch_event_rule" "guardduty" {
  name = "${var.name}-guardduty-findings"
  event_pattern = jsonencode({
    source        = ["aws.guardduty"]
    "detail-type" = ["GuardDuty Finding"]
    detail        = { severity = [{ numeric = [">=", 4] }] }
  })
}

resource "aws_cloudwatch_event_rule" "securityhub" {
  name = "${var.name}-securityhub-critical"
  event_pattern = jsonencode({
    source        = ["aws.securityhub"]
    "detail-type" = ["Security Hub Findings - Imported"]
    detail        = { findings = { Severity = { Label = ["CRITICAL", "HIGH"] } } }
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  for_each = {
    guardduty   = aws_cloudwatch_event_rule.guardduty.name
    securityhub = aws_cloudwatch_event_rule.securityhub.name
  }
  rule = each.value
  arn  = aws_sns_topic.alerts.arn
}
