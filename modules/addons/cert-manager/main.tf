provider "helm" {
  kubernetes {
    host                   = var.k8s_host
    cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
    client_certificate     = base64decode(var.k8s_client_certificate)
    client_key             = base64decode(var.k8s_client_key)
  }
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
