
output "password" {
  value     = module.argocd.password
  sensitive = true
}
