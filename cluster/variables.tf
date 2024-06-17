
variable "region" {
  description = "AWS region"
  type        = string
}

variable "domain_name" {
  description = "Route 53 domain name"
  type        = string
}

variable "secret_creds" {
  description = "aws secret manager store"
  type        = string
}

 variable "cluster_nodesize" {
  description = "cluster worker node initial node size"
  type        = string
  default = "small"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}




