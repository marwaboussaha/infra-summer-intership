data "aws_route53_zone" "this" {
  name         = var.hosted_zone_name
  private_zone = false
}

# Alias vers l'ALB
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
