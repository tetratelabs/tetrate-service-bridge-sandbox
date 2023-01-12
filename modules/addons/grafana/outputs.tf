output "password" {
  value     = coalesce(var.password, random_password.grafana.result)
  sensitive = true
}
