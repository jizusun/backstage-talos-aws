variable "cluster_name" {
  type = string
}

variable "log_bucket_id" {
  type    = string
  default = ""
}

variable "sns_topic_arn" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
