data "azuread_domains" "oidc" {
  only_initial = true
}

data "azurerm_client_config" "current" {
}

resource "azuread_application" "oidc" {
  display_name     = "${var.name_prefix}-oidc"
  sign_in_audience = "AzureADMyOrg"

  web {
    redirect_uris = ["https://${var.tctl_host}:8443/iam/v2/oidc/callback"]
    implicit_grant {
      access_token_issuance_enabled = true
    }
  }

  required_resource_access {
    resource_app_id = "00000002-0000-0000-c000-000000000000" # Azure AD Graph

    resource_access {
      id   = "5778995a-e1bf-45b8-affa-663a9f3f4d04" # Directory.Read.All
      type = "Role"
    }
  }
}

resource "null_resource" "oidc_grant_admin_consent" {
  provisioner "local-exec" {
    command = "az ad app permission admin-consent --id ${azuread_application.oidc.application_id}"
  }
  depends_on = [
    azuread_application.oidc
  ]
}

resource "azuread_application_password" "oidc" {
  application_object_id = azuread_application.oidc.object_id
}

resource "azuread_service_principal" "oidc" {
  application_id = azuread_application.oidc.application_id
}
