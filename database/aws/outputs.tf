output "db_instance_address" {
  description = "db instance address"
  value       = var.db_enable ? element(module.db[*].db_instance_address, 0) : ""
}

