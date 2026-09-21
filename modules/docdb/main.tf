resource "aws_docdb_subnet_group" "this" {
  name       = "${var.name}-docdb"
  subnet_ids = var.subnet_ids
}

resource "aws_docdb_cluster_parameter_group" "this" {
  name   = "${var.name}-docdb5"
  family = "docdb5.0"

  parameter {
    name  = "tls"
    value = "enabled"
  }

  parameter {
    name  = "audit_logs"
    value = "enabled"
  }
}

resource "aws_docdb_cluster" "this" {
  cluster_identifier = "${var.name}-docdb"
  engine             = "docdb"
  engine_version     = "5.0.0"

  master_username             = var.master_username
  manage_master_user_password = true # Secrets Manager + rotation gérée par AWS

  db_subnet_group_name            = aws_docdb_subnet_group.this.name
  vpc_security_group_ids          = [var.security_group_id]
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.this.name

  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  backup_retention_period      = var.backup_retention_days
  preferred_backup_window      = "02:00-03:00"
  preferred_maintenance_window = "sun:03:30-sun:04:30"

  enabled_cloudwatch_logs_exports = ["audit", "profiler"]

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name}-docdb-final"
}

# Instance 0 = primaire (AZ A), instance 1 = réplica de lecture (AZ B)
resource "aws_docdb_cluster_instance" "this" {
  count = length(var.azs)

  identifier                 = "${var.name}-docdb-${count.index}"
  cluster_identifier         = aws_docdb_cluster.this.id
  instance_class             = var.instance_class
  availability_zone          = var.azs[count.index]
  promotion_tier             = count.index
  auto_minor_version_upgrade = true
}
