# provisions cluster
module "cluster" {
  source        = "./cluster"
  count         = var.provision_cluster == "true"  ? 1 : 0
  providers    = { aws = aws }
  region     = var.region
  domain_name     = var.domain_name
  secret_creds     = var.secret_creds
  cluster_nodesize     = var.cluster_nodesize
  vpc_cidr     = var.vpc_cidr
  kubernetes_version     = var.kubernetes_version
 
 
}

# provisions DB
module "database" {
  source        = "./database"
  count         = var.provision_db  == "true"  ? 1 : 0
  providers    = { aws = aws }
  db_engine     = var.db_engine
  db_size     = var.db_size
  db_enable_multi_az     = var.db_enable_multi_az
  region     = var.region
  vpc_cidr     = var.vpc_cidr
  secret_creds  = var.secret_creds
  }




 module "gitops_bridge" {
  source        = "./gitops_bridge"
  blueprint_gitops_metadata = local.blueprint_gitops_metadata
  eks_cluster_endpoint     = local.eks_cluster_endpoint
  eks_cluster_certificate_authority_data =local.eks_cluster_certificate_authority_data
  git_ssh_key = local.git_ssh_key
  aws_cluster_name = local.aws_cluster_name
  aws_account_id = local.aws_account_id
  aws_vpc_id = local.aws_vpc_id
  aws_certificate_arn = local.aws_certificate_arn
  db_instance_address  = local.db_instance_address
  robusta_signing_key     = local.robusta_signing_key
  robusta_account_id     = local.robusta_account_id
  robusta_sink_token     = local.robusta_sink_token
  slack_api_key     = local.slack_api_key
  git_webhook_secret = local.git_webhook_secret
  service_account_role_arn = local.service_account_role_arn
  argocd_random_password = local.argocd_random_password
  argocd_bcrypt_hash  = local.argocd_bcrypt_hash
  domain_name = var.domain_name
  region     = var.region
  db_engine  = var.db_engine
  secret_creds     = var.secret_creds
  git_owner     = var.git_owner
  enable_git_ssh     = var.enable_git_ssh
  slack_channel = var.slack_channel
  ssh_key_path  = var.ssh_key_path
  kubernetes_version  = var.kubernetes_version
  addons_git_repo = var.addons_git_repo
  workload_git_repo = var.workload_git_repo
  addons_repo_path = var.addons_repo_path
  workload_repo_path = var.workload_repo_path
  addons_git_revision  = var.addons_git_revision
  workload_git_revision  = var.workload_git_revision
  cluster_bootstrap =var.cluster_bootstrap
  store_name        = var.store_name
  addons_argocd        = var.enable_argocd
  addons_argo_rollouts  = var.enable_argo_rollouts
  addons_ebs_csi        = var.enable_ebs_csi
  addons_external_secrets  = var.enable_external_secrets
  addons_load_balancer   = var.enable_ALB
  addons_karpenter       = var.enable_karpenter
  addons_external_dns    = var.enable_external_dns
  addons_grafana         = var.enable_grafana
  addons_loki            = var.enable_loki
  addons_autoscaler      = var.enable_pod_autoscaler
  addons_prometheus       = var.enable_prometheus
  addons_kyverno         = var.enable_kyverno
  addons_kubecost        = var.enable_kubecost
  addons_robusta         = var.enable_robusta
  addons_atlas           = var.enable_atlas
  addons_cloudwatch_metrics = var.enable_cloudwatch
  addons_metacontroller    = var.enable_metacontroller



  
 
 }

locals {
  aws_cluster_name      =  length(module.cluster) > 0 ? module.cluster[0].aws_cluster_name : ""
  aws_account_id =  length(module.cluster) > 0 ? module.cluster[0].aws_account_id : ""
  aws_vpc_id =  length(module.cluster) > 0 ? module.cluster[0].aws_vpc_id : ""
  aws_certificate_arn =  length(module.cluster) > 0 ? module.cluster[0].aws_certificate_arn : ""
  robusta_signing_key =  length(module.cluster) > 0 ? module.cluster[0].robusta_signing_key : ""
  robusta_account_id =  length(module.cluster) > 0 ? module.cluster[0].robusta_account_id : ""
  robusta_sink_token =  length(module.cluster) > 0 ? module.cluster[0].robusta_sink_token : ""
  slack_api_key =  length(module.cluster) > 0 ? module.cluster[0].slack_api_key : ""
  service_account_role_arn =  length(module.cluster) > 0 ? module.cluster[0].service_account_role_arn : ""
  blueprint_gitops_metadata =  length(module.cluster) > 0 ? module.cluster[0].blueprint_gitops_metadata : ""
  eks_cluster_endpoint =  length(module.cluster) > 0 ? module.cluster[0].eks_cluster_endpoint : ""
  eks_cluster_certificate_authority_data =  length(module.cluster) > 0 ? module.cluster[0].eks_cluster_certificate_authority_data : ""
  git_ssh_key =  length(module.cluster) > 0 ? module.cluster[0].git_ssh_key : ""
  argocd_random_password =  length(module.cluster) > 0 ? module.cluster[0].argocd_random_password : ""
  argocd_bcrypt_hash =  length(module.cluster) > 0 ? module.cluster[0].argocd_bcrypt_hash : ""
 
  git_webhook_secret =  length(module.cluster) > 0 ? module.cluster[0].git_webhook_secret : ""
  
  
}

locals {
  db_instance_address      = length(module.database) > 0 ? module.database[0].db_instance_address : ""
}

locals {
 
  configure_kubectl      = length(module.gitops_bridge) > 0 ? module.gitops_bridge[0].configure_kubectl : ""
  configure_argocd      = length(module.gitops_bridge) > 0 ? module.gitops_bridge[0].configure_argocd : ""
  access_argocd      = length(module.gitops_bridge) > 0 ? module.gitops_bridge[0].access_argocd : ""
}