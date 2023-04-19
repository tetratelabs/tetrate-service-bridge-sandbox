output "token" {
  value     = module.aws_k8s_auth[0].token
  sensitive = true
}