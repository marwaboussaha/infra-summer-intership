# Tous les SG vivent ici pour éviter les dépendances circulaires entre modules.
# Terraform supprime la règle egress ALLOW ALL créée par défaut par AWS.

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb"
  description = "ALB - 443 depuis Internet"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group" "frontend" {
  name        = "${var.name}-frontend"
  description = "Frontend - 8080 depuis ALB, aucune sortie Internet"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group" "backend" {
  name        = "${var.name}-backend"
  description = "Backend - 3000 depuis ALB"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group" "sandbox" {
  name        = "${var.name}-sandbox"
  description = "Sandbox - aucune sortie hors endpoints"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group" "endpoints" {
  name        = "${var.name}-endpoints"
  description = "VPC endpoints - 443 depuis le VPC"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group" "docdb" {
  name        = "${var.name}-docdb"
  description = "DocumentDB - 27017 depuis backend seul"
  vpc_id      = aws_vpc.this.id
}

# ---------- ALB ----------
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS Internet"
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  description       = "HTTP redirige vers 443"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_frontend" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.frontend.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

resource "aws_vpc_security_group_egress_rule" "alb_to_backend" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.backend.id
  ip_protocol                  = "tcp"
  from_port                    = 3000
  to_port                      = 3000
}

# ---------- Frontend ----------
resource "aws_vpc_security_group_ingress_rule" "frontend_from_alb" {
  security_group_id            = aws_security_group.frontend.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

# ---------- Backend ----------
resource "aws_vpc_security_group_ingress_rule" "backend_from_alb" {
  security_group_id            = aws_security_group.backend.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 3000
  to_port                      = 3000
}

resource "aws_vpc_security_group_egress_rule" "backend_to_docdb" {
  security_group_id            = aws_security_group.backend.id
  referenced_security_group_id = aws_security_group.docdb.id
  ip_protocol                  = "tcp"
  from_port                    = 27017
  to_port                      = 27017
}

resource "aws_vpc_security_group_egress_rule" "backend_to_sandbox" {
  security_group_id            = aws_security_group.backend.id
  referenced_security_group_id = aws_security_group.sandbox.id
  ip_protocol                  = "tcp"
  from_port                    = var.sandbox_port
  to_port                      = var.sandbox_port
}

resource "aws_vpc_security_group_egress_rule" "backend_https_out" {
  security_group_id = aws_security_group.backend.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "API Groq et API ECS via NAT"
}

# ---------- Sandbox ----------
resource "aws_vpc_security_group_ingress_rule" "sandbox_from_backend" {
  security_group_id            = aws_security_group.sandbox.id
  referenced_security_group_id = aws_security_group.backend.id
  ip_protocol                  = "tcp"
  from_port                    = var.sandbox_port
  to_port                      = var.sandbox_port
}

# ---------- Frontend + sandbox : images et logs via endpoints uniquement ----------
locals {
  endpoint_clients = {
    frontend = aws_security_group.frontend.id
    sandbox  = aws_security_group.sandbox.id
  }
}

resource "aws_vpc_security_group_egress_rule" "to_endpoints" {
  for_each = local.endpoint_clients

  security_group_id            = each.value
  referenced_security_group_id = aws_security_group.endpoints.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

resource "aws_vpc_security_group_egress_rule" "to_s3_gateway" {
  for_each = local.endpoint_clients

  security_group_id = each.value
  prefix_list_id    = aws_vpc_endpoint.s3.prefix_list_id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

# ---------- Endpoints ----------
resource "aws_vpc_security_group_ingress_rule" "endpoints_from_vpc" {
  security_group_id = aws_security_group.endpoints.id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

# ---------- DocumentDB ----------
resource "aws_vpc_security_group_ingress_rule" "docdb_from_backend" {
  security_group_id            = aws_security_group.docdb.id
  referenced_security_group_id = aws_security_group.backend.id
  ip_protocol                  = "tcp"
  from_port                    = 27017
  to_port                      = 27017
}
