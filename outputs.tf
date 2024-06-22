output "aws_cluster_name" {
  description = "aws cluster name"
  value       = local.aws_cluster_name
}

output "aws_account_id" {
  description = "aws account id"
  value       = local.aws_account_id
}

output "aws_certificate_arn" {
  description = "aws certificate arn"
  value       = local.aws_certificate_arn
}

output "service_account_role_arn" {
  description = "service account role arn"
  value       = local.service_account_role_arn
}

output "eks_cluster_endpoint" {
  description = "eks cluster endpoint"
  value       = local.eks_cluster_endpoint
}

output "db_instance_address" {
  description = "db instance address"
  value       = local.db_instance_address
}

