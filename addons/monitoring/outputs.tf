
output "grafana_password" {
  value     = module.grafana.admin_password
  sensitive = true
}
