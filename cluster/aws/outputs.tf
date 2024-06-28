output "aws_cluster_name" {
  description = "aws cluster name"
  value       = module.eks.cluster_name
}

output "aws_account_id" {
  description = "aws account id"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_vpc_id" {
  description = "aws vpc id"
  value       = module.vpc.vpc_id
}

output "aws_certificate_arn" {
  description = "aws certificate arn"
  value       = aws_acm_certificate_validation.this.certificate_arn 
}

output "service_account_role_arn" {
  description = "service account role arn"
  value       = module.controller_irsa.iam_role_arn
}

output "blueprint_gitops_metadata" {
  description = "blueprint gitops metadata"
  value       = module.eks_blueprints_addons.gitops_metadata
}

output "eks_cluster_endpoint" {
  description = "eks cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "eks cluster certificate"
  value       = module.eks.cluster_certificate_authority_data
}

output "robusta_signing_key" {
  description = "robusta signing key"
  value       = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string).ROBUSTA_SIGNING_KEY
}

output "robusta_account_id" {
  description = "robusta account id"
  value       = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string).ROBUSTA_ACCOUNT_ID
}

output "robusta_sink_token" {
  description = "robusta sink token"
  value       = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string).ROBUSTA_SINK_TOKEN
}

output "slack_api_key" {
  description = "slack api key"
  value       = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string).SLACK_API_KEY
}

output "git_ssh_key" {
  description = "git ssh key"
  value       = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string).SSH_KEY
}



output "argocd_random_password" {
  description = "argocd random password"
  value       = random_password.argocd.result
}

output "argocd_bcrypt_hash" {
  description = "argocd bcrypt hash"
  value       = bcrypt_hash.argo.id
}





