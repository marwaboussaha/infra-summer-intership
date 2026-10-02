variable "name" { type = string }
variable "region" { type = string }
variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }
variable "kms_key_arn" { type = string }
variable "log_retention_days" { type = number }

variable "sandbox_port" {
  description = "Port exposé par la sandbox au backend"
  type        = number
}

variable "enable_http_redirect" {
  description = "Ouvre le port 80 sur le SG de l'ALB (uniquement pour la redirection 301)"
  type        = bool
  default     = false
}