variable "name" { type = string }
variable "region" { type = string }
variable "account_id" { type = string }

variable "expiration_days" {
  type    = number
  default = 365
}
