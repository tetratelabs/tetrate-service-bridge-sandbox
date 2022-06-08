provider "helm" {
  kubernetes {
    host                   = var.k8s_host
    cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
    token                  = var.k8s_client_token
  }
}

provider "kubectl" {
  host                   = var.k8s_host
  cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
  token                  = var.k8s_client_token
  load_config_file       = false
}

resource "helm_release" "elasticsearch" {
  name             = "elasticsearch"
  repository       = "https://helm.elastic.co"
  chart            = "eck-operator"
  create_namespace = true
  namespace        = "elastic-system"
  timeout          = 900

  set {
    name  = "installCRDs"
    value = "true"
  }

}

resource "time_sleep" "wait_90_seconds" {
  depends_on      = [helm_release.elasticsearch]
  create_duration = "90s"
}

data "kubectl_path_documents" "manifests" {
  pattern          = "${path.module}/manifests/*.yaml"
  disable_template = true
}

resource "kubectl_manifest" "manifests" {
  count      = length(data.kubectl_path_documents.manifests.documents)
  yaml_body  = element(data.kubectl_path_documents.manifests.documents, count.index)
  depends_on = [time_sleep.wait_90_seconds]
}
