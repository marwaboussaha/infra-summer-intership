# ---------- Général ----------
variable "project" {
  type    = string
  default = "voicecraft"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "region" {
  type    = string
  default = "eu-west-3"
}

# ---------- Réseau ----------
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# ---------- DNS / TLS ----------
# Le domaine est enregistré chez GoDaddy. Terraform crée la zone Route 53,
# renvoie les 4 serveurs de noms (output route53_name_servers), et c'est
# toi qui les saisis chez GoDaddy pour déléguer la résolution DNS à AWS.
variable "hosted_zone_name" {
  description = "Domaine racine acheté chez GoDaddy (ex: voicecraft-pfe.com)"
  type        = string
}

variable "create_hosted_zone" {
  description = "true = Terraform crée la zone Route 53 (cas GoDaddy) ; false = elle existe déjà"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domaine servi par l'application (ex: app.voicecraft-pfe.com)"
  type        = string
}

variable "additional_domain_names" {
  description = "Noms supplémentaires pointant vers l'ALB et couverts par le certificat ACM"
  type        = list(string)
  default     = []
}

variable "alb_ssl_policy" {
  description = "Politique TLS du listener 443"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_http_redirect" {
  description = "false = HTTPS strict, aucun port 80 ; true = port 80 qui redirige en 301 vers 443"
  type        = bool
  default     = false
}

variable "waf_api_rate_limit" {
  type    = number
  default = 1000
}

# ---------- Conteneurs ----------
variable "ecr_repositories" {
  description = "Les 4 images construites par la pipeline"
  type        = list(string)
  default     = ["frontend", "backend", "sandbox", "worker"]
}

variable "image_tag" {
  description = "Tag immuable (SHA du commit applicatif), injecté par la CI"
  type        = string
}

variable "cpu_architecture" {
  type    = string
  default = "X86_64"
}

variable "backend_health_path" {
  type    = string
  default = "/api/health"
}

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

variable "sandbox_port" {
  type    = number
  default = 8000
}

variable "sandbox_cpu" {
  type    = number
  default = 512
}

variable "sandbox_memory" {
  type    = number
  default = 1024
}

# ---------- DocumentDB ----------
variable "docdb_instance_class" {
  type    = string
  default = "db.t4g.medium"
}

variable "docdb_master_username" {
  type    = string
  default = "voicecraft_admin"
}

# ---------- Observabilité ----------
variable "log_retention_days" {
  type    = number
  default = 90
}

variable "alert_email" {
  type = string
}

variable "monthly_budget_usd" {
  type    = number
  default = 300
}

variable "enable_guardduty" {
  type    = bool
  default = true
}

variable "enable_security_hub" {
  type    = bool
  default = true
}

variable "enable_config" {
  type    = bool
  default = true
}

variable "enable_inspector" {
  type    = bool
  default = true
}

# ---------- GitHub ----------
variable "github_repositories" {
  description = "Dépôts autorisés à assumer github_deploy (infra + app)"
  type        = list(string)
}

variable "create_github_oidc_provider" {
  type    = bool
  default = true
}

variable "tf_state_bucket" {
  type = string
}

variable "github_terraform_policy_arns" {
  type    = list(string)
  default = []
}