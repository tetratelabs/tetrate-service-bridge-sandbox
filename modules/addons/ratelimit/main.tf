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

resource "helm_release" "redis" {
  count            = var.enabled ? 1 : 0
  name             = "redis"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "redis"
  create_namespace = true
  namespace        = "ratelimit"
  timeout          = 900

  set {
    name  = "auth.password"
    value = var.redis_password
  }
  set {
    name  = "architecture"
    value = "standalone"
  }
}
