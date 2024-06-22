variable "db_enable" {
  description = "enable db"
  type        = bool
  default =  false
}

variable "db_engine" {
  description = "db engine"
  type        = string
  default  = "postgres"
}
variable "db_size" {
  description = "db size"
  type        = string
  default = "small"
}
variable "db_enable_multi_az" {
  description = "enable db multi az"
  type        = bool
  default = false
}

variable "region" {
  description = "AWS region"
  type        = string
}


variable "secret_store" {
  description = "aws secret manager store"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}
