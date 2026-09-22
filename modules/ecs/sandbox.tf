# Sandbox : 0 -> N via RunTask depuis le backend, pas de service.
# Aucun task role, filesystem en lecture seule, capabilities retirées.
resource "aws_ecs_task_definition" "sandbox" {
  family                   = "${var.name}-sandbox"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.sandbox_cpu
  memory                   = var.sandbox_memory
  execution_role_arn       = aws_iam_role.execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  # tmpfs n'est pas supporté sur Fargate : volume éphémère à la place
  volume {
    name = "tmp"
  }

  container_definitions = jsonencode([{
    name                   = "sandbox"
    image                  = local.image["sandbox"]
    essential              = true
    readonlyRootFilesystem = true
    user                   = "1000:1000"
    portMappings           = [{ containerPort = var.sandbox_port, protocol = "tcp" }]
    mountPoints            = [{ sourceVolume = "tmp", containerPath = "/tmp", readOnly = false }]
    linuxParameters = {
      capabilities = { drop = ["ALL"] }
    }
    logConfiguration = local.log_config["sandbox"]
  }])
}