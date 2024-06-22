# General
variable "name" {
  type        = string
  description = "Name of the resource"
  default = "alustan"
}

variable "tags" {
  type        = map(string)
  default     = {
    platform = "alustan"
  }
  description = "Tag for all resources"
}