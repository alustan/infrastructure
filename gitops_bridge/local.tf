
locals {
  argocd_subdomain = "argocd"
  argocd_host      = "${local.argocd_subdomain}-${terraform.workspace}.${var.domain_name}"
  github_url = var.enable_git_ssh == "true" ? "git@github.com:${var.git_owner}" : "https://github.com/${var.git_owner}"
 
   cluster_addons = {
    
    enable_argocd                          = var.addons_argocd == "true" ? true : false
    enable_argo_rollouts                   = var.addons_argo_rollouts == "true" ? true : false
    enable_aws_cloudwatch                  = var.addons_cloudwatch_metrics == "true" ? true : false
    enable_aws_ebs_csi                     = var.addons_ebs_csi == "true" ? true : false
    enable_external_secrets                = var.addons_external_secrets == "true" ? true : false
    enable_ALB_controller                  = var.addons_load_balancer == "true" ? true : false
    enable_karpenter                       = var.addons_karpenter == "true" ? true : false
    enable_external_dns                    = var.addons_external_dns == "true" ? true : false
    enable_grafana                         = var.addons_grafana == "true" ? true : false
    enable_loki_stack                      = var.addons_loki == "true" ? true : false
    enable_prometheus                      = var.addons_prometheus == "true" ? true : false
    enable_kyverno                         = var.addons_kyverno == "true" ? true : false
    enable_kubecost                        = var.addons_kubecost == "true" ? true : false
    enable_robusta                         = var.addons_robusta == "true" ? true : false
    enable_metrics_server                 = var.addons_metrics_server == "true" ? true : false
  
    
   
  }


   cluster_metadata = merge(
    var.blueprint_gitops_metadata,
    {
      aws_cluster_name = var.aws_cluster_name
      aws_region       = var.region
      aws_account_id   = var.aws_account_id
      aws_vpc_id       = var.aws_vpc_id
    },
     {
      argocd_domain                  = local.argocd_host
      external_dns_domain_filters = "[${var.domain_name}]"
      aws_certificate_arn         =  var.aws_certificate_arn
      db_instance_address         = var.db_instance_address
      service_account_role_arn    =  var.service_account_role_arn

      db_engine                   = var.db_engine
      secret_store                = var.secret_store
     
      slack_channel               = var.slack_channel
      git_owner                   = var.git_owner
      kubernetes_version          = var.kubernetes_version 
      environment                 = local.environment

      robusta_signing_key         =   var.robusta_signing_key
      robusta_account_id          =   var.robusta_account_id
      robusta_sink_token          =   var.robusta_sink_token
      slack_api_key               =   var.slack_api_key

    
      
      kube_cost_host              ="kubecost-${terraform.workspace}.${var.domain_name}"
      grafana_host                ="grafana-${terraform.workspace}.${var.domain_name}"
      prometheus_host             ="prometheus-${terraform.workspace}.${var.domain_name}"
     },
    {
      addons_repo_url      = "${local.github_url}/${var.addons_git_repo}"
      addons_repo_revision = var.addons_git_revision
    },
    {
     workload_repo_url      = "${local.github_url}/${var.workload_git_repo}"
     workload_repo_revision = var.workload_git_revision
    }
  )

}


################################################################################
# ArgoCD Cluster
################################################################################
locals {
 
  argocd_labels = merge({
    cluster_name                     = "in-cluster"
    environment                      = local.environment
    enable_argocd                    = true
   "argocd.argoproj.io/secret-type"  = "cluster"
    
    },
    try(local.cluster_addons, {})
  )

  argocd_annotations = merge(
    {
      cluster_name = "in-cluster"
      environment  = local.environment
    },
    try(local.cluster_metadata, {})
  )

  config = <<-EOT
    {
      "tlsClientConfig": {
        "insecure": false
      }
    }
  EOT

 
}




