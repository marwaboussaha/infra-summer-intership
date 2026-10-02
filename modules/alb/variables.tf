variable "name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "logs_bucket" { type = string }

variable "certificate_arn" {
  description = "ARN du certificat ACM validé, attaché au listener 443"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "Non utilise : l'association WAF est portee par modules/waf (evite le cycle alb -> waf -> alb)."
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "Politique TLS du listener 443"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_http_redirect" {
  description = "false = HTTPS strict (aucun port 80) ; true = 80 redirige en 301 vers 443"
  type        = bool
  default     = false
}

variable "backend_health_path" {
  type    = string
  default = "/api/health"
}

variable "deletion_protection" {
  type    = bool
  default = true
}