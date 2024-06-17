terraform {
  required_version = ">= 1.0"

  required_providers {
 
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.22.0"
    }
    
    argocd = {
      source  = "oboukili/argocd"
      version = "6.0.3"
    }
  }


}

provider "argocd" {
  port_forward_with_namespace = "argocd"
  username                    = "admin"
  password                    = var.argocd_random_password
  kubernetes {
    host                      = var.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(var.eks_cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", var.aws_cluster_name, "--region", var.region]
    }
  }
}


locals {
  name = "${terraform.workspace}-eks"
  environment = terraform.workspace

 tags = {
    Blueprint  = local.name
   }
}



provider "helm" {
  kubernetes {
    host                   = var.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(var.eks_cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", var.aws_cluster_name, "--region", var.region]
    }
  }
}

provider "kubernetes" {
  host                   = var.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(var.eks_cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", var.aws_cluster_name, "--region", var.region]
  }
}