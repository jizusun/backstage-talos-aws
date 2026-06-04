variable "cluster_name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "cluster_security_group_id" { type = string }
variable "environment" { type = string }

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "kms_key_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
