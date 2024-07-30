
variable "blueprint_gitops_metadata" {
  description = "blueprint gitops metadata"
  type        = any
  
}

variable "eks_cluster_endpoint" {
  description = "eks cluster endpoint"
  type        = string
  
}

variable "eks_cluster_certificate_authority_data" {
  description = "eks cluster certificate"
  type        = string
  
}
variable "git_ssh_key" {
  description = "aws stored git ssh key"
  type        = string
  
}

variable "domain_name" {
  description = "Route 53 domain name"
  type        = string
}

variable "aws_cluster_name" {
  description = "aws cluster name"
  type        = string
}

variable "aws_account_id" {
  description = "aws account id"
  type        = string
}

variable "aws_vpc_id" {
  description = "aws vpc id"
  type        = string
}

variable "aws_certificate_arn" {
  description = "aws certificate arn"
  type        = string
}

variable "db_instance_address" {
  description = "db instance address"
  type        = string
}

variable "db_name" {
  description = "db name"
  type        = string
}

variable "db_user" {
  description = "db user"
  type        = string
}

variable "db_password" {
  description = "db password"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "db_engine" {
  description = "db engine"
  type        = string
  default  = "postgres"
}
variable "secret_store" {
  description = "aws secret manager store"
  type        = string
}

variable "git_owner" {
  description = "name of repository owner"
  type        = string
 }

variable "addons_git_repo" {
  description = "name of Git repository"
  type        = string
  default = "cluster-manifests"
}
variable "workload_git_repo" {
  description = "name of Git repository"
  type        = string
  default = "cluster-manifests"
}

variable "addons_repo_path" {
  description = "Git repository base path for adddons manifest"
  type        = string
  default     = "control-plane"
}

variable "workload_repo_path" {
  description = "Git repository base path for workload manifest"
  type        = string
  default     = "workloads"
}

variable "addons_git_revision" {
  description = "Git repository revision/branch/ref k8s manifest"
  type        = string
  default     = "main"
}

variable "workload_git_revision" {
  description = "Git repository revision/branch/ref k8s manifest"
  type        = string
  default     = "main"
}

variable "enable_git_ssh" {
  description = "Use git ssh to access all git repos using format git@github.com:<org>"
  type        = string
  default = "false"
}

variable "robusta_signing_key" {
  description = "robusta signing key"
  type        = string

}

variable "robusta_account_id" {
  description = "robusta account id"
  type        = string

}

variable "robusta_sink_token" {
  description = "robusta sink token"
  type        = string

}

variable "container_registry_secret" {
  description = "container registry secret"
  type        = string

}



variable "slack_api_key" {
  description = "slack api key"
  type        = string

}



variable "service_account_role_arn" {
  description = "service account role arn"
  type        = string

}

variable "slack_channel" {
  description = "slack channel for notification"
  type        = string
 }

variable "ssh_key_path" {
  description = "SSH key path for git access"
  type        = string
  default     = "~/.ssh/id_ed25519"
 }

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "cluster_bootstrap" {
  description = "Git repository base path for k8s manifest"
  type        = string
  default     = "false"
}

variable "argocd_random_password" {
  description = "argocd random password"
  type        = string
 }

 variable "argocd_bcrypt_hash" {
  description = "argocd bcrypt hash"
  type        = string
 }

 
variable "addons_argocd" {
  description = "enable argocd addon"
  type        = string
  default = "true"
}
variable "addons_argo_rollouts" {
  description = "enable argo rollouts addon"
  type        = string
  default = "true"
}

variable "addons_ebs_csi" {
  description = "enable ebs csi addon"
  type        = string
  default = "true"
}
variable "addons_external_secrets" {
  description = "enable external secrets addon"
  type        = string
  default = "true"
}
variable "addons_load_balancer" {
  description = "enable aws loadbalancer addon"
  type        = string
  default = "true"
}
variable "addons_karpenter" {
  description = "enable karpenter addon"
  type        = string
  default = "true"
}
variable "addons_external_dns" {
  description = "enable external dns addon"
  type        = string
  default = "true"
}
variable "addons_grafana" {
  description = "enable grafana addon"
  type        = string
  default = "true"
}
variable "addons_loki" {
  description = "enable loki addon"
  type        = string
  default = "true"
}

variable "addons_prometheus" {
  description = "enable prometheus addon"
  type        = string
  default = "true"
}
variable "addons_kyverno" {
  description = "enable kyverno addon"
  type        = string
  default = "true"
}
variable "addons_kubecost" {
  description = "enable kubecost addon"
  type        = string
  default = "true"
}
variable "addons_robusta" {
  description = "enable robusta addon"
  type        = string
  default = "true"
}

variable "addons_cloudwatch_metrics" {
  description = "enable atlas addon"
  type        = string
  default = "true"
}

variable "addons_metrics_server" {
  description = "enable metrics server addon"
  type        = string
  default = "true"
}

variable "addons_alustan" {
  description = "enable alustan addon"
  type        = string
  default = "true"
}





