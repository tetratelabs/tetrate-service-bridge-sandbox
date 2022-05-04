provider "helm" {
  kubernetes {
    host                   = var.k8s_host
    cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
    client_certificate     = base64decode(var.k8s_client_certificate)
    client_key             = base64decode(var.k8s_client_key)
  }
}
provider "kubectl" {
  host                   = var.k8s_host
  cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
  client_certificate     = base64decode(var.k8s_client_certificate)
  client_key             = base64decode(var.k8s_client_key)
  load_config_file       = false
}
provider "kubernetes" {
  host                   = var.k8s_host
  cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
  client_certificate     = base64decode(var.k8s_client_certificate)
  client_key             = base64decode(var.k8s_client_key)
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.7.2"
  create_namespace = true
  namespace        = "cert-manager"

  set {
    name  = "installCRDs"
    value = "true"
  }

}

resource "time_sleep" "wait_90_seconds" {
  depends_on      = [helm_release.cert_manager]
  create_duration = "90s"
}

data "kubectl_path_documents" "manifests_selfsigned_ca" {
  pattern          = "${path.module}/manifests/selfsigned-ca.yaml"
  disable_template = true
}

resource "kubectl_manifest" "manifests_selfsigned_ca" {
  count      = length(data.kubectl_path_documents.manifests_selfsigned_ca.documents)
  yaml_body  = element(data.kubectl_path_documents.manifests_selfsigned_ca.documents, count.index)
  depends_on = [time_sleep.wait_90_seconds]
}

data "kubectl_path_documents" "manifests_tsb_server_cert" {
  pattern = "${path.module}/manifests/tsb-certs.yaml.tmpl"
  vars = {
    tsb_fqdn = var.tsb_fqdn
  }
}

resource "kubectl_manifest" "manifests_tsb_server_cert" {
  count      = length(data.kubectl_path_documents.manifests_tsb_server_cert.documents)
  yaml_body  = element(data.kubectl_path_documents.manifests_tsb_server_cert.documents, count.index)
  depends_on = [time_sleep.wait_90_seconds]
}

