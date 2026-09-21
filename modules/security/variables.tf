variable "name" { type = string }
variable "region" { type = string }
variable "account_id" { type = string }
variable "logs_bucket" { type = string }
variable "trail_name" { type = string }

# Mettre à false si le service est déjà activé (ex: AWS Organizations)
variable "enable_guardduty" {
  type    = bool
  default = true
}

variable "enable_security_hub" {
  type    = bool
  default = true
}

variable "enable_config" {
  type    = bool
  default = true
}

variable "enable_inspector" {
  type    = bool
  default = true
}
