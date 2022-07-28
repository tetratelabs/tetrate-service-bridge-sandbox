
output "es_ip" {
  value = data.kubernetes_service.es.status[0].load_balancer[0].ingress[0].ip
}

output "es_hostname" {
  value = data.kubernetes_service.es.status[0].load_balancer[0].ingress[0].hostname
}

output "es_username" {
  value = "elastic"
}

output "es_password" {
  value = data.kubernetes_secret.es_password.data["elastic"]
}

output "es_cacert" {
  value = data.kubernetes_secret.es_cacert.data["tls.crt"]
}
