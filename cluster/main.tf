


# Define the AWS module
module "aws_cluster" {
  source        = "./aws"
  region     = var.region
  domain_name     = var.domain_name
  secret_store     = var.secret_store
  cluster_nodesize     = var.cluster_nodesize
  vpc_cidr     = var.vpc_cidr
  kubernetes_version     = var.kubernetes_version

  
 }

# Define locals to handle conditional outputs
locals {
  aws_cluster_name      =  length(module.aws_cluster) > 0 ? module.aws_cluster[0].aws_cluster_name : ""
  aws_account_id =  length(module.aws_cluster) > 0 ? module.aws_cluster[0].aws_account_id : ""
  aws_vpc_id =  length(module.aws_cluster) > 0 ? module.aws_cluster[0].aws_vpc_id : ""
  aws_certificate_arn =  length(module.aws_cluster) > 0 ? module.aws_cluster[0].aws_certificate_arn : ""
  robusta_signing_key =  length(module.aws_cluster) > 0 ? module.aws_cluster[0].robusta_signing_key : ""
  robusta_account_id =  length(module.aws_cluster) > 0 ? module.aws_cluster[0].robusta_account_id : ""
  robusta_sink_token =  length(module.aws_cluster) > 0 ? module.aws_cluster[0].robusta_sink_token : ""
  slack_api_key =  length(module.aws_cluster) > 0 ? module.aws_cluster[0].slack_api_key : ""
  service_account_role_arn =  length(module.aws_cluster) > 0 ? module.aws_cluster[0].service_account_role_arn : ""
  blueprint_gitops_metadata =  length(module.aws_cluster) > 0 ? module.aws_cluster[0].blueprint_gitops_metadata : ""
  eks_cluster_endpoint =  length(module.aws_cluster) > 0 ? module.aws_cluster[0].eks_cluster_endpoint : ""
  eks_cluster_certificate_authority_data =  length(module.aws_cluster) > 0 ? module.aws_cluster[0].eks_cluster_certificate_authority_data : ""
  git_ssh_key =  length(module.aws_cluster) > 0 ? module.aws_cluster[0].git_ssh_key : ""
  argocd_random_password =  length(module.aws_cluster) > 0 ? module.aws_cluster[0].argocd_random_password : ""
  argocd_bcrypt_hash =  length(module.aws_cluster) > 0 ? module.aws_cluster[0].argocd_bcrypt_hash : ""
  container_registry_secret = length(module.aws_cluster) > 0 ? module.aws_cluster[0].container_registry_secret : ""
 


  

}
