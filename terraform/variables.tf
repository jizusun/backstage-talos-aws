variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the Talos Kubernetes cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,24}$", var.cluster_name))
    error_message = "Cluster name must be lowercase alphanumeric with hyphens, 3-25 chars."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "test", "perf", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, test, perf, staging, production."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "talos_version" {
  description = "Talos Linux version"
  type        = string
  default     = "v1.12.6"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.33.1"
}

variable "control_plane" {
  description = "Control plane configuration"
  type = object({
    count         = number
    instance_type = string
  })
}

variable "worker_groups" {
  description = "Worker node group configurations"
  type = list(object({
    name          = string
    instance_type = string
    desired_size  = number
  }))
}

variable "allowed_cidrs" {
  description = "CIDRs allowed to access the Kubernetes/Talos API"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "database" {
  description = "RDS database configuration"
  type = object({
    instance_class          = string
    allocated_storage       = number
    multi_az                = bool
    backup_retention_period = optional(number, 7)
  })
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
