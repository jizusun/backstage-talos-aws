output "cluster_name" {
  description = "Talos cluster name"
  value       = module.talos.cluster_name
}

output "lb_dns_name" {
  description = "Cluster load balancer DNS name"
  value       = module.talos.lb_dns_name
}

output "kubeconfig_path" {
  description = "Path to generated kubeconfig file"
  value       = module.talos.path_to_kubeconfig_file
}

output "database_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.endpoint
  sensitive   = true
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}
