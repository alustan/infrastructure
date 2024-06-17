# Define the AWS DB
module "aws_db" {
  source        = "./aws"
  region     = var.region
  db_engine     = var.db_engine
  db_size     = var.db_size
  db_enable_multi_az     = var.db_enable_multi_az
  vpc_cidr     = var.vpc_cidr
  secret_creds     = var.secret_creds
 
 }

# Define locals to handle conditional outputs
locals {
  db_instance_address      = length(module.aws_db) > 0 ? module.aws_db[0].db_instance_address : ""
}