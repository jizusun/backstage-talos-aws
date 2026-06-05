output "endpoint" {
  value = module.redis.replication_group_primary_endpoint_address
}

output "port" {
  value = 6379
}
