output "token" {
  value = data.azurerm_kubernetes_cluster.k8s.kube_config.0.password
}