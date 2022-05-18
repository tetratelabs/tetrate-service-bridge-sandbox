output "host" {
  value = module.eks.cluster_endpoint
}


output "cluster_ca_certificate" {
  value = base64decode(module.eks.cluster_certificate_authority_data)
}

output "token" {
  value = data.aws_eks_cluster_auth.cluster.token
}

output "kube_config_raw" {
  value = module.eks.kubeconfig
}

resource "local_file" "kubeconfig" {
  content  = module.eks.kubeconfig
  filename = "${var.cluster_name}-kubeconfig"
}

output "cluster_name" {
  value = var.cluster_name
}
