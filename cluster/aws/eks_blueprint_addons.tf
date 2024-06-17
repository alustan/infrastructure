
################################################################################
# EKS Blueprints Addons
################################################################################
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Using GitOps Bridge (Skip Helm Install in Terraform)
  create_kubernetes_resources = false


  # EKS Blueprints Addons
  enable_external_dns                 = true
  enable_external_secrets             = true
  enable_aws_load_balancer_controller = true
  enable_karpenter                    = true
  enable_aws_cloudwatch_metrics       = true


  external_dns_route53_zone_arns = [try(data.aws_route53_zone.this.arn, "")] 
  tags = local.tags

  depends_on = [module.eks]
}