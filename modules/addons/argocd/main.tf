provider "helm" {
  kubernetes {
    host                   = var.k8s_host
    cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
    client_certificate     = base64decode(var.k8s_client_certificate)
    client_key             = base64decode(var.k8s_client_key)
  }
}

resource "helm_release" "argocd" {
  name             = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  create_namespace = true
  namespace        = "argocd"
  timeout          = 900

  set {
    name  = "controller.enableStatefulSet"
    value = "true"
  }

  set {
    name  = "configs.secret.argocdServerAdminPassword"
    value = bcrypt(var.tsb_password)
  }
}
