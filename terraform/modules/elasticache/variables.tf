variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "cluster_security_group_id" {
  type = string
}

variable "node_type" {
  type    = string
  default = "cache.t3.micro"
}

variable "num_cache_clusters" {
  type    = number
  default = 1
}

variable "kms_key_id" {
  type        = string
  default     = null
  description = "KMS key for encryption"
}

variable "auth_token" {
  type        = string
  default     = null
  sensitive   = true
  description = "Auth token for Redis"
}

variable "tags" {
  type    = map(string)
  default = {}
}
