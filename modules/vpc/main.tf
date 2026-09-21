# 5 niveaux x 2 AZ :
# public 10.0.0-1 · app 10.0.10-11 · sandbox 10.0.20-21 · data 10.0.30-31 · endpoints 10.0.40-41
locals {
  tiers = {
    public    = 0
    app       = 10
    sandbox   = 20
    data      = 30
    endpoints = 40
  }

  subnets = merge([
    for tier, base in local.tiers : {
      for i, az in var.azs : "${tier}-${i}" => {
        tier = tier
        az   = az
        cidr = cidrsubnet(var.vpc_cidr, 8, base + i)
      }
    }
  ]...)

  subnet_ids = {
    for tier in keys(local.tiers) :
    tier => [for i in range(length(var.azs)) : aws_subnet.this["${tier}-${i}"].id]
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # DNS privé des endpoints
  tags                 = { Name = "${var.name}-vpc" }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-default-locked" }
}

resource "aws_subnet" "this" {
  for_each = local.subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name}-${each.key}"
    Tier = each.value.tier
  }
}

# ---------- IGW + NAT (1 par AZ) ----------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-igw" }
}

resource "aws_eip" "nat" {
  count  = length(var.azs)
  domain = "vpc"
  tags   = { Name = "${var.name}-nat-${count.index}" }
}

resource "aws_nat_gateway" "this" {
  count         = length(var.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = local.subnet_ids.public[count.index]
  tags          = { Name = "${var.name}-nat-${count.index}" }

  depends_on = [aws_internet_gateway.this]
}

# ---------- Route table publique : 0.0.0.0/0 -> IGW ----------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.name}-rt-public" }
}

resource "aws_route_table_association" "public" {
  count          = length(var.azs)
  subnet_id      = local.subnet_ids.public[count.index]
  route_table_id = aws_route_table.public.id
}

# ---------- Route table app : 0.0.0.0/0 -> NAT de son AZ ----------
resource "aws_route_table" "app" {
  count  = length(var.azs)
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = { Name = "${var.name}-rt-app-${count.index}" }
}

resource "aws_route_table_association" "app" {
  count          = length(var.azs)
  subnet_id      = local.subnet_ids.app[count.index]
  route_table_id = aws_route_table.app[count.index].id
}

# ---------- Route table isolée : local uniquement ----------
resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-rt-isolated" }
}

resource "aws_route_table_association" "isolated" {
  for_each = { for k, v in local.subnets : k => v if contains(["sandbox", "data", "endpoints"], v.tier) }

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.isolated.id
}

# ---------- Flow logs (trafic ALL) ----------
resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/vpc/${var.name}/flow-logs"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.name}-flow-logs"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "write-flow-logs"
  role = aws_iam_role.flow_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups", "logs:DescribeLogStreams"]
      Resource = [aws_cloudwatch_log_group.flow_logs.arn, "${aws_cloudwatch_log_group.flow_logs.arn}:*"]
    }]
  })
}

resource "aws_flow_log" "this" {
  vpc_id                   = aws_vpc.this.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow_logs.arn
  iam_role_arn             = aws_iam_role.flow_logs.arn
  max_aggregation_interval = 60
}
