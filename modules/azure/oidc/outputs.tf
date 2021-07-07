
output "application_client_id" {
  value = azuread_application.oidc.application_id
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "openid_configuration" {
  value = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0/.well-known/openid-configuration"
}

output "secret" {
  value = azuread_application_password.oidc.value
}


resource "local_file" "kubeconfig" {
  content  = azuread_application_password.oidc.value
  filename = "oidc-secret"
}
