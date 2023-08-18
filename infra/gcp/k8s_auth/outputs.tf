output "token" {
  value     = module.gcp_k8s_auth.token
  sensitive = true
}