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

resource "helm_release" "fluxcd" {
  name             = "flux2"
  repository       = "https://fluxcd-community.github.io/helm-charts"
  chart            = "flux2"
  create_namespace = true
  namespace        = "flux-system"
  timeout          = 900
  description      = var.cluster_name
}

data "kubectl_path_documents" "applications" {
    pattern = var.applications
}

resource "kubectl_manifest" "applications" {
    for_each   = toset(data.kubectl_path_documents.applications.documents)
    yaml_body  = each.value
    depends_on = [helm_release.fluxcd]
}