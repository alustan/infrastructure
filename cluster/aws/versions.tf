terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.67.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.22.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.3.2"
    }
   bcrypt = {
      source  = "viktorradnai/bcrypt"
      version = ">= 0.1.2"
    }
   
  }


}


data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
  name = "${terraform.workspace}"
  environment = terraform.workspace
  
  tags = {
    Blueprint  = local.name
   }
}




