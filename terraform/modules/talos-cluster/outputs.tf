output "cluster_name" {
  value = module.talos.cluster_name
}

output "lb_dns_name" {
  value = module.talos.lb_dns_name
}

output "kubeconfig" {
  value     = module.talos.kubeconfig
  sensitive = true
}

output "kubeconfig_path" {
  value = module.talos.path_to_kubeconfig_file
}

output "talosconfig_path" {
  value = module.talos.path_to_talosconfig_file
}

output "cluster_security_group_id" {
  value = data.aws_security_groups.cluster.ids[0]
}
