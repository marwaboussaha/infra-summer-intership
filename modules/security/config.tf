# ---------- AWS Config : dérive de configuration ----------
resource "aws_iam_role" "config" {
  count = var.enable_config ? 1 : 0
  name  = "${var.name}-config"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "config.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config" {
  count      = var.enable_config ? 1 : 0
  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "this" {
  count    = var.enable_config ? 1 : 0
  name     = "${var.name}-recorder"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  count          = var.enable_config ? 1 : 0
  name           = "${var.name}-channel"
  s3_bucket_name = var.logs_bucket
  s3_key_prefix  = "config"
  depends_on     = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  count      = var.enable_config ? 1 : 0
  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.this]
}

resource "aws_config_config_rule" "managed" {
  for_each = var.enable_config ? toset([
    "S3_BUCKET_PUBLIC_READ_PROHIBITED",
    "VPC_FLOW_LOGS_ENABLED",
    "CLOUD_TRAIL_ENABLED",
    "IAM_ROOT_ACCESS_KEY_CHECK",
    "ECR_PRIVATE_IMAGE_SCANNING_ENABLED",
  ]) : toset([])

  name = lower(replace(each.key, "_", "-"))

  source {
    owner             = "AWS"
    source_identifier = each.key
  }

  depends_on = [aws_config_configuration_recorder_status.this]
}
