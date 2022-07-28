provider "kubectl" {
  host                   = var.k8s_host
  cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
  token                  = var.k8s_client_token
  load_config_file       = false
}

provider "kubernetes" {
  host                   = var.k8s_host
  cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
  token                  = var.k8s_client_token
}

resource "kubectl_server_version" "current" {}

resource "kubernetes_namespace" "bookinfo" {
  metadata {
    name = "bookinfo"
    labels = {
      "istio.io/rev" = "tsb-stable"
    }
  }
}

data "kubectl_path_documents" "manifests" {
  pattern          = "${path.module}/manifests/*.yaml"
  disable_template = true
}

resource "kubectl_manifest" "manifests" {
  count              = length(data.kubectl_path_documents.manifests.documents)
  yaml_body          = element(data.kubectl_path_documents.manifests.documents, count.index)
  depends_on         = [kubernetes_namespace.bookinfo]
  override_namespace = "bookinfo"
}

