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

provider "kubernetes" {
  host                   = var.k8s_host
  cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
  token                  = var.k8s_client_token
}

resource "helm_release" "cert_manager" {
  count            = var.cert-manager_enabled == true ? 1 : 0
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.7.2"
  create_namespace = true
  namespace        = "cert-manager"
  timeout          = 900

  set {
    name  = "installCRDs"
    value = "true"
  }
  set {
    name  = "featureGates"
    value = "ExperimentalCertificateSigningRequestControllers=true"
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
  count      = var.cert-manager_enabled == true ? length(data.kubectl_path_documents.manifests_selfsigned_ca.documents) : 0
  yaml_body  = element(data.kubectl_path_documents.manifests_selfsigned_ca.documents, count.index)
  depends_on = [time_sleep.wait_90_seconds]
}


