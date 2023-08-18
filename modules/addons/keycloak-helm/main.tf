provider "helm" {
  kubernetes {
    host                   = var.k8s_host
    cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
    token                  = var.k8s_client_token
  }
}

provider "kubernetes" {
  host                   = var.k8s_host
  cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
  token                  = var.k8s_client_token
}

resource "helm_release" "keycloak" {
  name             = "keycloak"
  repository       = "https://codecentric.github.io/helm-charts"
  chart            = "keycloak"
  create_namespace = true
  namespace        = "keycloak"
  timeout          = 300
  description      = var.cluster_name

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "extraEnv"
    value = <<EOF
- name: KEYCLOAK_USER
  value: admin
- name: KEYCLOAK_PASSWORD
  value: ${var.password}
- name: KEYCLOAK_LOGLEVEL
  value: DEBUG
EOF
  }
}

data "kubernetes_service" "keycloak" {
  metadata {
    name      = "keycloak-http"
    namespace = "keycloak"
  }
  depends_on = [helm_release.keycloak]
}

