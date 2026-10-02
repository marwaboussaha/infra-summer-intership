variable "hosted_zone_name" {
  description = "Domaine racine acheté chez GoDaddy (ex : voicecraft-pfe.com)"
  type        = string
}

variable "create_zone" {
  description = "true = Terraform crée la zone Route 53 ; false = la zone existe déjà"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domaine servi par l'application (ex : app.voicecraft-pfe.com)"
  type        = string
}

variable "additional_domain_names" {
  description = "Noms supplémentaires pointant aussi vers l'ALB (ex : le domaine racine)"
  type        = list(string)
  default     = []
}

variable "create_caa_record" {
  description = "Enregistrement CAA limitant l'émission de certificats à Amazon"
  type        = bool
  default     = true
}

variable "alb_dns_name" {
  description = "Nom DNS de l'ALB"
  type        = string
}

variable "alb_zone_id" {
  description = "Zone hébergée de l'ALB (fournie par AWS)"
  type        = string
}