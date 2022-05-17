output "azure_jumpbox_public_ip" {
  value      = module.azure_jumpbox.public_ip
  depends_on = [module.azure_jumpbox]
}

output "azure_jumpbox_ssh_username" {
  value      = var.jumpbox_username
  depends_on = [module.azure_jumpbox]
}

output "tsb_fqdn" {
  value = var.tsb_fqdn
}


