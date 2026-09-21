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
