output "token" {
  value     = module.gcp_k8s_auth[0].token
  sensitive = true
}