output "host" {
  value = module.tsb_mp.host
}

output "tsb_cacert" {
  value = module.tsb_mp.tsb_cacert
}

output "istiod_cacerts_tls_crt" {
  value = module.tsb_mp.istiod_cacerts_tls_crt
}

output "istiod_cacerts_tls_key" {
  value = module.tsb_mp.istiod_cacerts_tls_key
}


output "es_host" {
  value = module.es.es_host
}

output "es_username" {
  value = module.es.es_username
}

output "es_password" {
  value = module.es.es_password
}

output "es_cacert" {
  value = module.es.es_cacert
}
