output "alb_arn" { value = aws_lb.this.arn }
output "arn_suffix" { value = aws_lb.this.arn_suffix }
output "dns_name" { value = aws_lb.this.dns_name }
output "zone_id" { value = aws_lb.this.zone_id }

# Lus depuis le listener / la règle : le service ECS attend que le routage existe.
output "frontend_target_group_arn" { value = aws_lb_listener.http.default_action[0].target_group_arn }
output "backend_target_group_arn" { value = aws_lb_listener_rule.api.action[0].target_group_arn }
output "backend_target_group_arn_suffix" { value = aws_lb_target_group.backend.arn_suffix }