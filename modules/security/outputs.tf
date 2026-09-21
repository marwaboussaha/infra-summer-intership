output "guardduty_detector_id" { value = try(aws_guardduty_detector.this[0].id, null) }
output "cloudtrail_arn" { value = aws_cloudtrail.this.arn }
output "access_analyzer_arn" { value = aws_accessanalyzer_analyzer.this.arn }
