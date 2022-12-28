
output "grafana_password" {
  value     = module.grafana.password
  sensitive = true
}
