#  #######################################################################
#  Required values
#  #######################################################################
variable "cluster_bootstrap" {
  description = "bootstrap control cluster from local machine"
  type        = string
  default     = "false"
}
 
 variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}
 
variable "provision_cluster" {
  description = "provisions cluster"
  type        = string
  default   = "true"

}

variable "provision_db" {
  description = "provisions database"
  type        = string
  default   = "false"

}

variable "domain_name" {
  description = "Route 53 domain name"
  type        = string
  default    = "example.com"
}



# ############################################################################################################ 

 variable "cloud_provider" {
  description = "cloud provider"
  type        = string
  default  = "aws"

}

variable "region" {
  description = "AWS region"
  type        = string
  default = "us-west-2"
}

variable "secret_store" {
  description = "aws secret manager store"
  type        = string
  default    = "creds_store"
}

 variable "cluster_nodesize" {
  description = "cluster worker node initial node size"
  type        = string
  default = "small"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}


variable "db_engine" {
  description = "db engine"
  type        = string
  default  = "postgres"
}
variable "db_size" {
  description = "db size"
  type        = string
  default = "small"
}
variable "db_enable_multi_az" {
  description = "enable db multi az"
  type        = string
  default = "false"
}

variable "git_owner" {
  description = "name of repository owner"
  type        = string
  default     = "alustan"
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
  description = "Git repository base path for addons manifest"
  type        = string
  default     = "control-plane"
}

variable "workload_repo_path" {
  description = "Git repository base path for workload manifest"
  type        = string
  default     = "workloads"
}

variable "addons_git_revision" {
  description = "Git repository revision/branch/ref for addons manifest"
  type        = string
  default     = "main"
}

variable "workload_git_revision" {
  description = "Git repository revision/branch/ref for workload manifest"
  type        = string
  default     = "main"
}

variable "slack_channel" {
  description = "slack channel for notification"
  type        = string
  default    = "alerts"
 }

variable "ssh_key_path" {
  description = "SSH key path for git access"
  type        = string
  default     = "~/.ssh/id_ed25519"
 }

variable "enable_git_ssh" {
  description = "Use git ssh to access all git repos using format git@github.com:<org>"
  type        = string
  default = "false"
}

variable "workspace" {
  description = "terraform workspace"
  type        = string
  default   =   "default"
 }

variable "enable_argocd" {
  description = "enable argocd addon"
  type        = string
  default = "true"
}
variable "enable_argo_rollouts" {
  description = "enable argo rollouts addon"
  type        = string
  default = "true"
}

variable "enable_ebs_csi" {
  description = "enable ebs csi addon"
  type        = string
  default = "true"
}
variable "enable_external_secrets" {
  description = "enable external secrets addon"
  type        = string
  default = "true"
}
variable "enable_ALB" {
  description = "enable aws loadbalancer addon"
  type        = string
  default = "true"
}
variable "enable_karpenter" {
  description = "enable karpenter addon"
  type        = string
  default = "true"
}
variable "enable_external_dns" {
  description = "enable external dns addon"
  type        = string
  default = "true"
}
variable "enable_grafana" {
  description = "enable grafana addon"
  type        = string
  default = "true"
}
variable "enable_loki" {
  description = "enable loki addon"
  type        = string
  default = "true"
}

variable "enable_prometheus" {
  description = "enable prometheus addon"
  type        = string
  default = "true"
}
variable "enable_kyverno" {
  description = "enable kyverno addon"
  type        = string
  default = "true"
}
variable "enable_kubecost" {
  description = "enable kubecost addon"
  type        = string
  default = "true"
}
variable "enable_robusta" {
  description = "enable robusta addon"
  type        = string
  default = "true"
}

variable "enable_cloudwatch" {
  description = "enable atlas addon"
  type        = string
  default = "true"
}

variable "enable_metrics_server" {
  description = "enable metrics server addon"
  type        = string
  default = "true"
}




