output "registry" {
  value = module.aws_base[0].registry
}

output "registry_username" {
  value = module.aws_base[0].registry_username
}

output "registry_password" {
  value = module.aws_base[0].registry_password
  sensitive = true
}

output "public_ip" {
  value = module.aws_jumpbox[0].public_ip
}

output "pkey" {
  value     = module.aws_jumpbox[0].pkey
  sensitive = true
}

output "cluster_name" {
  value = module.aws_k8s[0].cluster_name
}

output "host" {
  value     = module.aws_k8s[0].host
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = module.aws_k8s[0].cluster_ca_certificate
  sensitive = true
}

output "token" {
  value     = module.aws_k8s[0].token
  sensitive = true
}

output "locality_region" {
  value = var.aws_k8s_region
}

output "vpc_id" {
  value = module.aws_base[0].vpc_id
}

output "oidc_provider_arn" {
  value = module.aws_k8s[0].oidc_provider_arn
}

output "cluster_oidc_issuer_url" {
  value = module.aws_k8s[0].cluster_oidc_issuer_url
}