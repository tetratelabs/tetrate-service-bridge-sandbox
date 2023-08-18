output "public_ip" {
  value = azurerm_public_ip.jumpbox_public_ip.ip_address
}

output "pkey" {
  value = tls_private_key.generated.private_key_pem
}
