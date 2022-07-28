
output "ingress_ip" {
  value = data.kubernetes_service.tsb.status[0].load_balancer[0].ingress[0].ip
}

output "ingress_hostname" {
  value = data.kubernetes_service.tsb.status[0].load_balancer[0].ingress[0].hostname
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
