
output "admin_password" {
  value     = random_password.grafana.result
  sensitive = true
}
