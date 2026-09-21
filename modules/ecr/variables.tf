variable "name" { type = string }
variable "kms_key_arn" { type = string }

variable "repositories" {
  type = list(string)
}

variable "keep_last_images" {
  type    = number
  default = 30
}
