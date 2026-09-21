# ---------- Clusters ----------
resource "aws_ecs_cluster" "app" {
  name = "${var.name}-app"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Fargate : chaque tâche tourne dans sa propre microVM Firecracker
resource "aws_ecs_cluster" "sandbox" {
  name = "${var.name}-sandbox"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "app" {
  cluster_name       = aws_ecs_cluster.app.name
  capacity_providers = ["FARGATE"]
}

resource "aws_ecs_cluster_capacity_providers" "sandbox" {
  cluster_name       = aws_ecs_cluster.sandbox.name
  capacity_providers = ["FARGATE"]
}

resource "aws_cloudwatch_log_group" "this" {
  for_each = toset(["frontend", "backend", "sandbox"])

  name              = "/ecs/${var.name}/${each.key}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

locals {
  image = { for k, url in var.repository_urls : k => "${url}:${var.image_tag}" }

  log_config = {
    for k, lg in aws_cloudwatch_log_group.this : k => {
      logDriver = "awslogs"
      options = {
        awslogs-group         = lg.name
        awslogs-region        = var.region
        awslogs-stream-prefix = k
      }
    }
  }
}
