# ============================================================
# L'application n'est plus jointe par le nom DNS de l'ALB mais par
# le domaine, en HTTPS. Le job apply du pipeline lit app_url.
# ============================================================
output "app_url" {
  description = "URL publique de l'application"
  value       = "https://${var.domain_name}"
}

# ------------------------------------------------------------
# À coller chez GoDaddy après le premier apply :
#   My Products -> ton domaine -> DNS -> Nameservers -> Change
#   -> I'll use my own nameservers -> les 4 valeurs ci-dessous
# ------------------------------------------------------------
output "route53_name_servers" {
  description = "Les 4 serveurs de noms AWS a saisir chez GoDaddy"
  value       = module.dns.name_servers
}

output "route53_zone_id" {
  description = "Identifiant de la zone hebergee Route 53"
  value       = module.dns.zone_id
}

output "acm_certificate_arn" {
  description = "Certificat TLS attache au listener 443"
  value       = module.acm.certificate_arn
}

output "alb_dns_name" {
  description = "Nom DNS interne de l'ALB (cible de l'alias Route 53)"
  value       = module.alb.dns_name
}

output "nat_public_ips" {
  description = "IP sortantes (à déclarer chez Groq si allowlist)"
  value       = module.vpc.nat_public_ips
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "docdb_endpoint" {
  value = module.docdb.endpoint
}

output "docdb_secret_arn" {
  value = module.docdb.master_secret_arn
}

output "groq_api_key_parameter" {
  value = module.secrets.groq_api_key_name
}

output "github_deploy_role_arn" {
  description = "Variable GitHub AWS_DEPLOY_ROLE_ARN"
  value       = module.github_oidc.role_arn
}

output "ecs_app_cluster" {
  value = module.ecs.app_cluster_name
}

output "ecs_sandbox_cluster" {
  value = module.ecs.sandbox_cluster_name
}

output "alerts_topic_arn" {
  value = module.monitoring.alerts_topic_arn
}

output "logs_bucket" {
  value = module.logging.bucket_id
}