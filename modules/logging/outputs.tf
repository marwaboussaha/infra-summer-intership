# Exposé via la policy : les modules consommateurs attendent qu'elle soit posée.
output "bucket_id" { value = aws_s3_bucket_policy.this.bucket }
output "bucket_arn" { value = aws_s3_bucket.this.arn }
output "trail_name" { value = local.trail_name }
