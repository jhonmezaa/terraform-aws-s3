output "primary_bucket_id" {
  description = "Primary bucket ID"
  value       = module.primary_bucket.bucket_ids["source"]
}

output "primary_bucket_arn" {
  description = "Primary bucket ARN"
  value       = module.primary_bucket.bucket_arns["source"]
}

output "replica_bucket_id" {
  description = "Replica bucket ID"
  value       = module.replica_bucket.bucket_ids["destination"]
}

output "replica_bucket_arn" {
  description = "Replica bucket ARN"
  value       = module.replica_bucket.bucket_arns["destination"]
}

output "replication_role_arn" {
  description = "Replication IAM role ARN"
  value       = aws_iam_role.replication.arn
}

output "replication_enabled" {
  description = "Replication status"
  value       = module.primary_bucket.replication_enabled["source"]
}
