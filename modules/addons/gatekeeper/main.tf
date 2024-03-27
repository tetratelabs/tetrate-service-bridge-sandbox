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

# Gatekeeper Deployment using helm chart
resource "helm_release" "gatekeeper" {
  count             = var.gatekeeper_enabled == true ? 1 : 0
  name              = "gatekeeper"
  repository        = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart             = "gatekeeper"
  version           =  var.gatekeeper_version
  create_namespace  = true
  namespace         = "gatekeeper-system"
  timeout           =  240
  
  values = [
    file("${path.module}/manifests/gatekeeper-values.yaml")
  ]
}