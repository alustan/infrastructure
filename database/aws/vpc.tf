locals {
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr = var.vpc_cidr
}
################################################################################
# Supporting Resources
################################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = var.vpc_cidr
  azs  = local.azs



  database_subnets =  var.db_enable == true ? [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 6)] : null 

  
  create_database_subnet_group =var.db_enable == true ? true : false

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}
