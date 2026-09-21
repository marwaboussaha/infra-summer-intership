variable "name" { type = string }
variable "account_id" { type = string }

variable "github_repositories" {
  description = "Dépôts autorisés (org/repo) : infra + application"
  type        = list(string)
}

variable "create_oidc_provider" {
  description = "false si le fournisseur OIDC GitHub existe déjà dans le compte"
  type        = bool
  default     = true
}

variable "ecr_repository_arns" { type = list(string) }
variable "kms_key_arn" { type = string }
variable "tf_state_bucket" { type = string }

variable "extra_policy_arns" {
  description = "Politiques nécessaires à terraform apply depuis la CI"
  type        = list(string)
  default     = []
}
