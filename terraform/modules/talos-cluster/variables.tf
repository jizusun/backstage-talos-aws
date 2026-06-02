variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "control_plane" {
  type = object({
    count         = number
    instance_type = string
  })
}

variable "worker_groups" {
  type = list(object({
    name          = string
    instance_type = string
    desired_size  = number
    min_size      = number
    max_size      = number
    capacity_type = optional(string, "ON_DEMAND")
  }))
}

variable "talos_version" {
  type    = string
  default = "v1.12.6"
}

variable "kubernetes_version" {
  type    = string
  default = "1.33.1"
}

variable "allowed_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
