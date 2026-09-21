variable "name" { type = string }
variable "kms_key_arn" { type = string }
variable "resource_arns" { type = list(string) }

variable "retention_days" {
  type    = number
  default = 35
}

variable "schedule" {
  type    = string
  default = "cron(0 3 * * ? *)"
}
