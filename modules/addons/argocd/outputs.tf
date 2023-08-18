
output "password" {
  value     = coalesce(var.password, random_password.argocd.result)
  sensitive = true
}
