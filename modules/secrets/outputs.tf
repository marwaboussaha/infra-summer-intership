output "groq_api_key_arn" { value = aws_ssm_parameter.groq_api_key.arn }
output "groq_api_key_name" { value = aws_ssm_parameter.groq_api_key.name }
output "jwt_secret_arn" { value = aws_ssm_parameter.jwt_secret.arn }
