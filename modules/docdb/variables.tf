variable "name" { type = string }
variable "azs" { type = list(string) }
variable "subnet_ids" { type = list(string) }
variable "security_group_id" { type = string }
variable "kms_key_arn" { type = string }

variable "instance_class" {
  type    = string
  default = "db.t4g.medium"
}

variable "master_username" {
  type    = string
  default = "voicecraft_admin"
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "deletion_protection" {
  type    = bool
  default = true
}
