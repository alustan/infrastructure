terraform {
  required_version = ">= 1.7.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.34"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }
}