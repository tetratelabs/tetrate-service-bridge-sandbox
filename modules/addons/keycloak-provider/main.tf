provider "keycloak" {
  client_id = "admin-cli"
  username  = var.username
  password  = var.password
  url       = var.endpoint
}

resource "keycloak_realm" "realm" {
  realm        = "tetrate"
  enabled      = true
  display_name = "tetrate"
}
