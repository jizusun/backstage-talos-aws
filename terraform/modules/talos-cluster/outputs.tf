output "cluster_name" {
  value = var.cluster_name
}

output "lb_dns_name" {
  value = aws_lb.api.dns_name
}

output "kubeconfig_path" {
  value = local_file.kubeconfig.filename
}

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "controlplane_ips" {
  value = aws_instance.controlplane[*].public_ip
}

output "cluster_security_group_id" {
  value = aws_security_group.cluster.id
}
