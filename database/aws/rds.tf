################################################################################
# RDS Module
################################################################################
module "db" {
  count = var.db_enable ? 1 : 0

  source = "terraform-aws-modules/rds/aws"

  identifier = "${local.name}-db"

  engine               = var.db_engine
  engine_version       = var.db_engine == "postgres" ? "14" : "5.7"
  family               = var.db_engine == "postgres" ? "postgres14" : "mysql5.7"
  major_engine_version = var.db_engine == "postgres" ? "14" : "5.7"
  instance_class = (
    var.db_size == "small" ? "db.t4g.small" : (
      var.db_size == "medium" ? "db.t4g.medium" : "db.t4g.large"
    )
  )
  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string).DB_NAME
  username = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string).DB_USER
  password = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string).DB_PASSWORD
  port     = var.db_engine == "postgres" ? 5432 : 3306

  multi_az               = var.db_enable_multi_az
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [element(module.security_group[*].security_group_id, 0)]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  backup_retention_period         = 1
  skip_final_snapshot             = true
  deletion_protection             = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "monitoring-role-name"
  monitoring_role_use_name_prefix       = true
  monitoring_role_description           = "Description for monitoring role"

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  tags = local.tags
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
  depends_on = [module.security_group]
}

module "security_group" {
  count = var.db_enable ? 1 : 0
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name}-db-sg"
  description = "Complete DB security group"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = var.db_engine == "postgres" ? 5432 : 3306
      to_port     = var.db_engine == "postgres" ? 5432 : 3306
      protocol    = "tcp"
      description = "DB access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = local.tags
}