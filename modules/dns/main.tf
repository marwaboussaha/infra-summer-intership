# ============================================================
# Route 53 — zone publique du domaine acheté chez GoDaddy
#
#   create_zone = true   -> Terraform CRÉE la zone hébergée et renvoie
#                           les 4 serveurs de noms à coller chez GoDaddy
#   create_zone = false  -> la zone existe déjà dans le compte, on la lit
#
# Le domaine reste enregistré chez GoDaddy : seule la résolution DNS
# est déléguée à AWS (enregistrements NS).
# ============================================================

resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0

  name          = var.hosted_zone_name
  comment       = "Zone publique ${var.hosted_zone_name} - deleguee depuis GoDaddy"
  force_destroy = false
}

data "aws_route53_zone" "existing" {
  count = var.create_zone ? 0 : 1

  name         = var.hosted_zone_name
  private_zone = false
}

locals {
  zone_id = var.create_zone ? aws_route53_zone.this[0].zone_id : data.aws_route53_zone.existing[0].zone_id

  name_servers = var.create_zone ? aws_route53_zone.this[0].name_servers : data.aws_route53_zone.existing[0].name_servers

  # Domaine principal + éventuels alias (ex : le domaine racine)
  alias_records = toset(concat([var.domain_name], var.additional_domain_names))
}

# ------------------------------------------------------------
# Alias A -> ALB
# Un alias Route 53 ne coûte rien et suit l'IP de l'ALB automatiquement.
# ------------------------------------------------------------
resource "aws_route53_record" "app" {
  for_each = local.alias_records

  zone_id = local.zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# ------------------------------------------------------------
# CAA : seul ACM a le droit d'émettre un certificat pour ce domaine.
# Empêche une autre autorité de certification d'émettre à votre place.
# ------------------------------------------------------------
resource "aws_route53_record" "caa" {
  count = var.create_caa_record ? 1 : 0

  zone_id = local.zone_id
  name    = var.hosted_zone_name
  type    = "CAA"
  ttl     = 300

  records = [
    "0 issue \"amazon.com\"",
    "0 issuewild \"amazon.com\"",
  ]
}