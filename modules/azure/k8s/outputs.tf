output "host" {
  value = azurerm_kubernetes_cluster.k8s.kube_config.0.host
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate
}

output "client_key" {
  value = azurerm_kubernetes_cluster.k8s.kube_config.0.client_key
}

output "cluster_ca_certificate" {
  value = azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate
}

output "username" {
  value = azurerm_kubernetes_cluster.k8s.kube_config.0.username
}

output "token" {
  value = azurerm_kubernetes_cluster.k8s.kube_config.0.password
}

output "kube_config_raw" {
  value = azurerm_kubernetes_cluster.k8s.kube_config_raw
}

resource "local_file" "kubeconfig" {
  content  = azurerm_kubernetes_cluster.k8s.kube_config_raw
  filename = "${var.output_path}/${var.cluster_name}-kubeconfig"
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.k8s.name
}

output "kubelet_identity" {
  value = azurerm_kubernetes_cluster.k8s.kubelet_identity
}

output "locality_region" {
  value = var.location
}