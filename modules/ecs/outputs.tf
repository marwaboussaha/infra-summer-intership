output "app_cluster_name" { value = aws_ecs_cluster.app.name }
output "sandbox_cluster_name" { value = aws_ecs_cluster.sandbox.name }
output "frontend_service_name" { value = aws_ecs_service.frontend.name }
output "backend_service_name" { value = aws_ecs_service.backend.name }
output "execution_role_arn" { value = aws_iam_role.execution.arn }
output "backend_task_role_arn" { value = aws_iam_role.backend_task.arn }
