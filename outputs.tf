output "app_url" {
  value = "https://${var.domain_name}"
}

output "alb_dns_name" {
  value = module.alb.dns_name
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
