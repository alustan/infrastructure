terraform {
 required_version = ">= 1.0"
 required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.67.0"
    }

    port = {
      source  = "port-labs/port-labs"
      version = "~> 1.0.0"
    }
    
  }
}

provider "aws" {
 region = var.region
}

