# Frontend : nginx, bundle Vite statique, aucun secret, pas de task role
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.name}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  container_definitions = jsonencode([{
    name             = "frontend"
    image            = local.image["frontend"]
    essential        = true
    portMappings     = [{ containerPort = 8080, protocol = "tcp" }]
    logConfiguration = local.log_config["frontend"]
  }])
}

resource "aws_ecs_service" "frontend" {
  name             = "frontend"
  cluster          = aws_ecs_cluster.app.id
  task_definition  = aws_ecs_task_definition.frontend.arn
  desired_count    = var.frontend_desired_count
  launch_type      = "FARGATE"
  platform_version = "LATEST"
  propagate_tags   = "SERVICE"

  network_configuration {
    subnets          = var.app_subnet_ids
    security_groups  = [var.frontend_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.frontend_target_group_arn
    container_name   = "frontend"
    container_port   = 8080
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}
