output "ingress_ip" {
  value = module.tsb_mp.ingress_ip
}

output "ingress_hostname" {
  value = module.tsb_mp.ingress_hostname
}

output "fqdn" {
  value = var.tsb_fqdn
}

output "tsb_cacert" {
  value     = module.tsb_mp.tsb_cacert
  sensitive = true
}

output "istiod_cacerts_tls_crt" {
  value     = module.tsb_mp.istiod_cacerts_tls_crt
  sensitive = true
}

output "istiod_cacerts_tls_key" {
  value     = module.tsb_mp.istiod_cacerts_tls_key
  sensitive = true
}

output "es_ip" {
  value = module.es.es_ip
}

output "es_hostname" {
  value = module.es.es_hostname
}

output "es_username" {
  value = module.es.es_username
}

output "es_password" {
  value     = module.es.es_password
  sensitive = true
}

output "es_cacert" {
  value     = module.es.es_cacert
  sensitive = true
}
