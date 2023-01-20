output "dns_project" {
  value = local.dns_project
}

output "dns_credentials" {
  value     = base64decode(google_service_account_key.external_dns_key.private_key)
  sensitive = true
}
