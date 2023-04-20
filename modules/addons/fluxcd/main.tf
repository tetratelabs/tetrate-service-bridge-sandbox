provider "helm" {
  kubernetes {
    host                   = var.k8s_host
    cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
    token                  = var.k8s_client_token
  }
}

resource "helm_release" "fluxcd" {
  name             = "flux2"
  repository       = "https://fluxcd-community.github.io/helm-charts"
  chart            = "flux2"
  create_namespace = true
  namespace        = "flux-system"
  timeout          = 900
  description      = var.cluster_name
}

resource "kubectl_manifest" "manifests_fluxcd_apps" {
  for_each   = var.applications
  yaml_body  = each.value
  depends_on = [helm_release.fluxcd]
}
