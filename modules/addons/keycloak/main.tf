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

resource "helm_release" "keycloak" {
  name             = "keycloak"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "keycloak"
  create_namespace = true
  namespace        = "keycloak"
  timeout          = 300
  description      = var.cluster_name

  set {
    name  = "auth.createAdminUser"
    value = "true"
  }
  set {
    name  = "auth.adminUser"
    value = "admin"
  }
  set {
    name  = "auth.adminPassword"
    value = var.tsb_password
  }
  set {
    name  = "service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "externalDatabase.password"
    value = var.tsb_password
  }
}
