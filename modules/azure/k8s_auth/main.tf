data "azurerm_kubernetes_cluster" "k8s" {
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
}