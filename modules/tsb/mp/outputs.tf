
output "ingress_ip" {
  value = data.kubernetes_service.tsb.status[0].load_balancer[0].ingress[0].ip
}

output "ingress_hostname" {
  value = data.kubernetes_service.tsb.status[0].load_balancer[0].ingress[0].hostname
}

output "tsb_cacert" {
  value = data.kubernetes_secret.selfsigned_ca.data["tls.crt"]
}

output "password" {
  value     = coalesce(var.tsb_password, random_password.tsb.result)
  sensitive = true
}
