variable "name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "certificate_arn" { type = string }
variable "logs_bucket" { type = string }

variable "ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "backend_health_path" {
  type    = string
  default = "/api/health"
}

variable "deletion_protection" {
  type    = bool
  default = true
}
