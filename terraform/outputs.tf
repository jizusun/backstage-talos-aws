output "cluster_name" {
  description = "Talos cluster name"
  value       = module.talos_cluster.cluster_name
}

output "control_plane_ip" {
  description = "Control plane load balancer IP"
  value       = module.talos_cluster.lb_dns_name
}

output "kubeconfig_path" {
  description = "Path to kubeconfig file"
  value       = module.talos_cluster.kubeconfig_path
}

output "database_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.endpoint
  sensitive   = true
}

output "backstage_url" {
  description = "Backstage application URL"
  value       = module.talos_cluster.lb_dns_name
}
