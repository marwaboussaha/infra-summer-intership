# Clé Groq : valeur renseignée hors Terraform (voir README)
resource "aws_ssm_parameter" "groq_api_key" {
  name   = "/${var.project}/${var.environment}/groq_api_key"
  type   = "SecureString"
  key_id = var.kms_key_arn
  value  = "CHANGE_ME"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "random_password" "jwt" {
  length  = 64
  special = false
}

resource "aws_ssm_parameter" "jwt_secret" {
  name   = "/${var.project}/${var.environment}/jwt_secret"
  type   = "SecureString"
  key_id = var.kms_key_arn
  value  = random_password.jwt.result
}
