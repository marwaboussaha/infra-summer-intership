output "zone_id" {
  description = "Identifiant de la zone hébergée Route 53"
  value       = local.zone_id
}

output "name_servers" {
  description = "Les 4 serveurs de noms à saisir chez GoDaddy (Nameservers personnalisés)"
  value       = local.name_servers
}

output "fqdn" {
  description = "Nom complet de l'application"
  value       = aws_route53_record.app[var.domain_name].fqdn
}