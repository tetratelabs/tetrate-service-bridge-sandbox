output "host" {
  value = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  value = module.eks.cluster_certificate_authority_data
}

output "token" {
  value = data.aws_eks_cluster_auth.cluster.token
}

output "client_certificate" {
  value = ""
}

output "client_key" {
  value = ""
}

output "cluster_name" {
  value = var.cluster_name
}

output "locality_region" {
  value = var.region
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}