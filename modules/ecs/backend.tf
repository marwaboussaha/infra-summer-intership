# Backend : Express, 2 -> 10 tâches, cible CPU 70 %
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.name}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.backend_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  container_definitions = jsonencode([{
    name         = "backend"
    image        = local.image["backend"]
    essential    = true
    portMappings = [{ containerPort = 3000, protocol = "tcp" }]

    environment = [
      { name = "NODE_ENV", value = "production" },
      { name = "PORT", value = "3000" },
      { name = "DOCDB_HOST", value = var.docdb_endpoint },
      { name = "DOCDB_READER_HOST", value = var.docdb_reader_endpoint },
      { name = "DOCDB_PORT", value = "27017" },
      { name = "DOCDB_USER", value = var.docdb_username },
      { name = "DOCDB_TLS", value = "true" },
      { name = "SANDBOX_CLUSTER", value = aws_ecs_cluster.sandbox.name },
      { name = "SANDBOX_TASK_DEFINITION", value = aws_ecs_task_definition.sandbox.family },
      { name = "SANDBOX_SUBNETS", value = join(",", var.sandbox_subnet_ids) },
      { name = "SANDBOX_SECURITY_GROUP", value = var.sandbox_sg_id },
      { name = "SANDBOX_PORT", value = tostring(var.sandbox_port) },
    ]

    secrets = [
      { name = "DOCDB_PASSWORD", valueFrom = "${var.docdb_secret_arn}:password::" },
      { name = "GROQ_API_KEY", valueFrom = var.groq_api_key_arn },
      { name = "JWT_SECRET", valueFrom = var.jwt_secret_arn },
    ]

    logConfiguration = local.log_config["backend"]
  }])
}

resource "aws_ecs_service" "backend" {
  name             = "backend"
  cluster          = aws_ecs_cluster.app.id
  task_definition  = aws_ecs_task_definition.backend.arn
  desired_count    = var.backend_min_count
  launch_type      = "FARGATE"
  platform_version = "LATEST"
  propagate_tags   = "SERVICE"

  network_configuration {
    subnets          = var.app_subnet_ids
    security_groups  = [var.backend_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.backend_target_group_arn
    container_name   = "backend"
    container_port   = 3000
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [desired_count] # géré par l'auto scaling
  }
}

resource "aws_appautoscaling_target" "backend" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.app.name}/${aws_ecs_service.backend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.backend_min_count
  max_capacity       = var.backend_max_count
}

resource "aws_appautoscaling_policy" "backend_cpu" {
  name               = "${var.name}-backend-cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.backend.service_namespace
  resource_id        = aws_appautoscaling_target.backend.resource_id
  scalable_dimension = aws_appautoscaling_target.backend.scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value       = var.backend_cpu_target
    scale_in_cooldown  = 120
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
