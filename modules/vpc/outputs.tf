output "vpc_id" { value = aws_vpc.this.id }

output "public_subnet_ids" { value = local.subnet_ids.public }
output "app_subnet_ids" { value = local.subnet_ids.app }
output "sandbox_subnet_ids" { value = local.subnet_ids.sandbox }
output "data_subnet_ids" { value = local.subnet_ids.data }
output "endpoints_subnet_ids" { value = local.subnet_ids.endpoints }

output "nat_public_ips" { value = aws_eip.nat[*].public_ip }

output "alb_sg_id" { value = aws_security_group.alb.id }
output "frontend_sg_id" { value = aws_security_group.frontend.id }
output "backend_sg_id" { value = aws_security_group.backend.id }
output "sandbox_sg_id" { value = aws_security_group.sandbox.id }
output "docdb_sg_id" { value = aws_security_group.docdb.id }
output "endpoints_sg_id" { value = aws_security_group.endpoints.id }
