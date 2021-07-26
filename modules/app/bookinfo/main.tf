
provider "kubernetes" {
  host                   = var.k8s_host
  cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
  client_certificate     = base64decode(var.k8s_client_certificate)
  client_key             = base64decode(var.k8s_client_key)
}

provider "kubectl" {
  host                   = var.k8s_host
  cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
  client_certificate     = base64decode(var.k8s_client_certificate)
  client_key             = base64decode(var.k8s_client_key)
  load_config_file       = false
}

resource "kubectl_server_version" "current" {}

resource "kubernetes_namespace" "bookinfo" {
  metadata {
    name = "bookinfo"
    labels = {
      istio-injection = "enabled"
    }
  }
}

data "kubectl_path_documents" "manifests" {
  pattern          = "${path.module}/manifests/*.yaml"
  disable_template = true
}

resource "kubectl_manifest" "manifests" {
  count      = length(data.kubectl_path_documents.manifests.documents)
  yaml_body  = element(data.kubectl_path_documents.manifests.documents, count.index)
  depends_on = [kubernetes_namespace.bookinfo]
  override_namespace = "bookinfo"
}

