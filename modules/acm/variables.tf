variable "domain_name" {
  description = "Nom principal du certificat (ex : app.voicecraft-pfe.com)"
  type        = string
}

variable "zone_id" {
  description = "Zone Route 53 dans laquelle écrire les CNAME de validation"
  type        = string
}

variable "subject_alternative_names" {
  description = "Noms additionnels couverts par le même certificat"
  type        = list(string)
  default     = []
}

variable "key_algorithm" {
  description = "RSA_2048 est accepté par tous les clients ; EC_prime256v1 est plus rapide"
  type        = string
  default     = "RSA_2048"
}

variable "validation_timeout" {
  description = "Durée maximale d'attente de la validation DNS"
  type        = string
  default     = "45m"
}