output "host" {
  value = data.kubernetes_service.keycloak.status[0].load_balancer[0].ingress[0].ip
}

output "username" {
  value = "admin"
}

output "password" {
  value = var.password
}
