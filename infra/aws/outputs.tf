output "registry" {
  value = module.aws_base.registry
}

output "registry_username" {
  value = module.aws_base.registry_username
}

output "registry_password" {
  value     = module.aws_base.registry_password
  sensitive = true
}

output "public_ip" {
  value = module.aws_jumpbox.public_ip
}

output "pkey" {
  value     = module.aws_jumpbox.pkey
  sensitive = true
}

output "cluster_name" {
  value = module.aws_k8s.cluster_name
}

output "host" {
  value     = module.aws_k8s.host
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = module.aws_k8s.cluster_ca_certificate
  sensitive = true
}

output "token" {
  value     = module.aws_k8s.token
  sensitive = true
}

output "locality_region" {
  value = local.cluster.region
}

output "vpc_id" {
  value = module.aws_base.vpc_id
}

output "oidc_provider_arn" {
  value = module.aws_k8s.oidc_provider_arn
}

output "cluster_oidc_issuer_url" {
  value = module.aws_k8s.cluster_oidc_issuer_url
}