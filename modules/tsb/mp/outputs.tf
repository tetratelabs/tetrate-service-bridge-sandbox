
output "host" {
  value = data.kubernetes_service.tsb.status[0].load_balancer[0].ingress[0].ip
}

output "tsb_cacert" {
  value = data.kubernetes_secret.selfsigned_ca.data["tls.crt"]
}

output "istiod_cacerts_tls_crt" {
  value = data.kubernetes_secret.istiod_cacerts.data["tls.crt"]
}

output "istiod_cacerts_tls_key" {
  value = data.kubernetes_secret.istiod_cacerts.data["tls.key"]
}
output "es_host" {
  value = data.kubernetes_service.es.status[0].load_balancer[0].ingress[0].ip
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


