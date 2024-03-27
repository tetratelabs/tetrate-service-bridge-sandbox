output "ingress_ip" {
  value = module.tsb_mp.ingress_ip
}

output "ingress_hostname" {
  value = module.tsb_mp.ingress_hostname
}

output "fqdn" {
  value = local.tetrate.fqdn
}

output "tsb_cacert" {
  value     = module.tsb_mp.tsb_cacert
  sensitive = true
}

output "es_username" {
  value     = module.tsb_mp.es_username
  sensitive = true
}

output "es_password" {
  value     = module.tsb_mp.es_password
  sensitive = true
}

output "es_cacert" {
  value     = module.tsb_mp.tsb_cacert
  sensitive = true
}

output "registry" {
  value = data.terraform_remote_state.infra.outputs.registry
}

output "tsb_password" {
  value     = module.tsb_mp.password
  sensitive = true
}
