output "token" {
  value     = module.azure_k8s_auth[0].token
  sensitive = true
}