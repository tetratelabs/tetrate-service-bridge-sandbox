resource "random_string" "random" {
  length  = 8
  special = false
  lower   = true
  upper   = false
  numeric = false
}

resource "google_project" "tsb" {
  count           = var.gcp_project_id == null ? 1 : 0
  name            = "${var.name_prefix}-tsb"
  project_id      = "${var.name_prefix}-tsb-${random_string.random.result}"
  org_id          = var.gcp_org_id
  billing_account = var.gcp_billing_id
}
