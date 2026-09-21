# ---------- GuardDuty + Runtime Monitoring ECS Fargate ----------
resource "aws_guardduty_detector" "this" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true
}

resource "aws_guardduty_detector_feature" "runtime" {
  count       = var.enable_guardduty ? 1 : 0
  detector_id = aws_guardduty_detector.this[0].id
  name        = "RUNTIME_MONITORING"
  status      = "ENABLED"

  additional_configuration {
    name   = "ECS_FARGATE_AGENT_MANAGEMENT"
    status = "ENABLED"
  }
}

# ---------- Security Hub ----------
resource "aws_securityhub_account" "this" {
  count                    = var.enable_security_hub ? 1 : 0
  enable_default_standards = false
}

resource "aws_securityhub_standards_subscription" "fsbp" {
  count         = var.enable_security_hub ? 1 : 0
  standards_arn = "arn:aws:securityhub:${var.region}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.this]
}

# ---------- Inspector : CVE continues sur ECR ----------
resource "aws_inspector2_enabler" "this" {
  count          = var.enable_inspector ? 1 : 0
  account_ids    = [var.account_id]
  resource_types = ["ECR"]
}

# ---------- Access Analyzer ----------
resource "aws_accessanalyzer_analyzer" "this" {
  analyzer_name = "${var.name}-analyzer"
  type          = "ACCOUNT"
}

# ---------- CloudTrail ----------
resource "aws_cloudtrail" "this" {
  name                          = var.trail_name
  s3_bucket_name                = var.logs_bucket
  s3_key_prefix                 = "cloudtrail"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
}
