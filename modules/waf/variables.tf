variable "name" { type = string }
variable "alb_arn" { type = string }
variable "logs_bucket_arn" { type = string }

variable "api_rate_limit" {
  description = "Requêtes max par IP sur /api/* par fenêtre de 5 min"
  type        = number
  default     = 1000
}
