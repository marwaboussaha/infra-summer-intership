output "cluster_arn" { value = aws_docdb_cluster.this.arn }
output "cluster_identifier" { value = aws_docdb_cluster.this.cluster_identifier }
output "endpoint" { value = aws_docdb_cluster.this.endpoint }
output "reader_endpoint" { value = aws_docdb_cluster.this.reader_endpoint }
output "master_username" { value = aws_docdb_cluster.this.master_username }
output "master_secret_arn" { value = aws_docdb_cluster.this.master_user_secret[0].secret_arn }
