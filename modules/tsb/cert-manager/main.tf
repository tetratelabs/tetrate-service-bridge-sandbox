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

data "kubectl_path_documents" "certmanager" {
  pattern          = "${path.module}/manifests/cert-manager.yaml"
  disable_template = true
}

resource "kubectl_manifest" "certmanager" {
  count     = length(data.kubectl_path_documents.certmanager.documents)
  yaml_body = element(data.kubectl_path_documents.certmanager.documents, count.index)
}
