terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.67.0"
    }
   
   
  }
}



data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
  name = terraform.workspace
  environment = terraform.workspace
  
  tags = {
    Blueprint  = local.name
   }
}



