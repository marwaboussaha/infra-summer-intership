variable "name" { type = string }
variable "region" { type = string }
variable "account_id" { type = string }
variable "kms_key_arn" { type = string }

variable "log_retention_days" {
  type    = number
  default = 90
}

# ---------- Images ----------
variable "repository_urls" {
  description = "Map nom -> URL ECR (doit contenir frontend, backend, sandbox)"
  type        = map(string)
}

variable "image_tag" { type = string }

variable "cpu_architecture" {
  type    = string
  default = "X86_64"
}

# ---------- Réseau ----------
variable "app_subnet_ids" { type = list(string) }
variable "sandbox_subnet_ids" { type = list(string) }
variable "frontend_sg_id" { type = string }
variable "backend_sg_id" { type = string }
variable "sandbox_sg_id" { type = string }

# ---------- ALB ----------
variable "frontend_target_group_arn" { type = string }
variable "backend_target_group_arn" { type = string }

# ---------- Dimensionnement ----------
variable "frontend_desired_count" {
  type    = number
  default = 2
}

variable "backend_min_count" {
  type    = number
  default = 2
}

variable "backend_max_count" {
  type    = number
  default = 10
}

variable "backend_cpu_target" {
  type    = number
  default = 70
}

variable "sandbox_port" { type = number }

variable "sandbox_cpu" {
  type    = number
  default = 512
}

variable "sandbox_memory" {
  type    = number
  default = 1024
}

# ---------- Données et secrets ----------
variable "docdb_endpoint" { type = string }
variable "docdb_reader_endpoint" { type = string }
variable "docdb_username" { type = string }
variable "docdb_secret_arn" { type = string }
variable "groq_api_key_arn" { type = string }
variable "jwt_secret_arn" { type = string }
