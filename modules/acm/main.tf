# ============================================================
# ACM — certificat TLS public, validé par DNS dans Route 53
#
# Le certificat doit vivre dans la MÊME région que l'ALB (eu-west-3).
# La validation DNS est automatique : ACM demande un enregistrement
# CNAME, Terraform le crée dans la zone, puis attend la validation.
# Le renouvellement est ensuite automatique tant que le CNAME reste.
# ============================================================

resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"
  key_algorithm             = var.key_algorithm

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  # Le nouveau certificat est créé avant que l'ancien soit retiré du listener
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = var.domain_name
  }
}

# Enregistrements CNAME de validation (dédoublonnés : un SAN identique
# au domaine principal renvoie deux fois la même option de validation)
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options :
    dvo.resource_record_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id         = var.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# Bloque le plan tant qu'ACM n'a pas émis le certificat.
# Si la délégation NS chez GoDaddy n'est pas faite, cette étape
# tourne jusqu'au timeout : c'est le signe que les NS sont à corriger.
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]

  timeouts {
    create = var.validation_timeout
  }
}