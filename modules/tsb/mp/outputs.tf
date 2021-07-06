output "kubectl_server_version" {
  value = kubectl_server_version.current
}

output "es_host" {
  value = data.kubernetes_service.es.status[0].load_balancer[0].ingress[0].ip
}

output "es_password" {
  value = data.kubernetes_secret.es_password.data["elastic"]
}

output "es_cacert" {
  value = data.kubernetes_secret.es_cacert.data["tls.crt"]
}

output "host" {
  value = data.kubernetes_service.tsb.status[0].load_balancer[0].ingress[0].ip
}