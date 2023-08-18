output "token" {
  value     = module.azure_k8s_auth.token
  sensitive = true
}