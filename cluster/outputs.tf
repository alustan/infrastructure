
output "aws_cluster_name" {
  description = "aws cluster name"
  value       = local.aws_cluster_name
}

output "aws_account_id" {
  description = "aws account id"
  value       = local.aws_account_id
}

output "aws_vpc_id" {
  description = "aws vpc id"
  value       = local.aws_vpc_id
}

output "aws_certificate_arn" {
  description = "aws certificate arn"
  value       = local.aws_certificate_arn
}

output "service_account_role_arn" {
  description = "service account role arn"
  value       = local.service_account_role_arn
}

output "blueprint_gitops_metadata" {
  description = "blueprint gitops metadata"
  value       = local.blueprint_gitops_metadata
}

output "eks_cluster_endpoint" {
  description = "eks cluster endpoint"
  value       = local.eks_cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "eks cluster certificate"
  value       = local.eks_cluster_certificate_authority_data
}

output "git_ssh_key" {
  description = "git ssh key"
  value       = local.git_ssh_key
}



output "robusta_signing_key" {
  description = "robusta signing key"
  value       = local.robusta_signing_key
}

output "robusta_account_id" {
  description = "robusta account id"
  value       = local.robusta_account_id
}

output "robusta_sink_token" {
  description = "robusta sink token"
  value       = local.robusta_sink_token
}

output "slack_api_key" {
  description = "robusta sink token"
  value       = local.slack_api_key
}

output "argocd_random_password" {
  description = "argocd random password"
  value       = local.argocd_random_password
}

output "argocd_bcrypt_hash" {
  description = "argocd bcrypt hash"
  value       = local.argocd_bcrypt_hash
}





