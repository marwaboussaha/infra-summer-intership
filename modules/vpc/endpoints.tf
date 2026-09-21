locals {
  interface_endpoints = {
    ecr-api = "ecr.api"
    ecr-dkr = "ecr.dkr"
    logs    = "logs"
    ssm     = "ssm"
    secrets = "secretsmanager"
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.subnet_ids.endpoints
  security_group_ids  = [aws_security_group.endpoints.id]

  tags = { Name = "${var.name}-vpce-${each.key}" }
}

# Gateway S3 : gratuit, requis par ECR (couches d'images)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(aws_route_table.app[*].id, [aws_route_table.isolated.id])

  tags = { Name = "${var.name}-vpce-s3" }
}
