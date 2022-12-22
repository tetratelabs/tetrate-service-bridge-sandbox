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

resource "helm_release" "argocd" {
  name             = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  create_namespace = true
  namespace        = "argocd"
  timeout          = 900
  description      = var.cluster_name
  set {
    name  = "controller.enableStatefulSet"
    value = "true"
  }

  set {
    name  = "configs.secret.argocdServerAdminPassword"
    value = bcrypt(var.password)
  }

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }
}

resource "kubectl_manifest" "manifests_argocd_apps" {
  for_each = var.applications
  yaml_body  = each.value
  depends_on = [helm_release.argocd]
}
