
data "external" "gcr_token" {
  program = ["bash", "${path.module}/internal-cr-token.sh"]
  query = {
    "tsb_version" = var.tsb_version
    "cached_by"   = var.cached_by
  }
}
