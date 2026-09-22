variable "name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "logs_bucket" { type = string }

variable "backend_health_path" {
  type    = string
  default = "/api/health"
}

variable "deletion_protection" {
  type    = bool
  default = true
}