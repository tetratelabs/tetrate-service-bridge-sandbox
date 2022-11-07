output "internal_cr" {
  value = data.external.gcr_token.result.registry
}

output "internal_cr_token" {
  value = data.external.gcr_token.result.token
  sensitive = true
}
