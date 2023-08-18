output "token" {
  value     = module.aws_k8s_auth.token
  sensitive = true
}