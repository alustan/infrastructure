output "db_instance_address" {
  description = "db instance address"
  value       = module.db.db_instance_address
}

output "db_name" {
  description = "db name"
  value       = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string).DB_NAME
}

output "db_user" {
  description = "db user"
  value       = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string).DB_USER
}

output "db_password" {
  description = "db password"
  value       = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string).DB_PASSWORD
}
