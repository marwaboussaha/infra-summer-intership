variable "hosted_zone_name" {
  description = "Zone Route 53 publique existante"
  type        = string
}

variable "domain_name" { type = string }
variable "alb_dns_name" { type = string }
variable "alb_zone_id" { type = string }
