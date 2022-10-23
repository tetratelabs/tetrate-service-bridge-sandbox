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

resource "kubectl_server_version" "current" {}

data "kubectl_path_documents" "services" {
  for_each = {
    eshop    = "products,orders"
    checkout = "checkout"
    payments = "payments,accounting" 
  }
  pattern = "${path.module}/manifests/apps/services.yaml"
  vars    = {
    namespace = each.key
    services = each.value
  }
}

data "kubectl_path_documents" "ingress" {
  pattern = "${path.module}/manifests/apps/ingress.yaml"
  disable_template = true
}

data "kubectl_path_documents" "trafficgen" {
  pattern = "${path.module}/manifests/apps/trafficgen.yaml"
  vars    = {
    eshop_host                = var.eshop_host
    payments_host             = var.payments_host
    checkout_error_percentage = var.checkout_error_percentage
    payments_latency_ms       = var.payments_latency_ms
  }
}

resource "kubernetes_namespace" "eshop" {
  for_each = toset(["eshop", "checkout", "payments", "trafficgen"])
  metadata {
    name = each.value
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

resource "kubectl_manifest" "services" {
  for_each = merge(
    data.kubectl_path_documents.services["eshop"].manifests,
    data.kubectl_path_documents.services["checkout"].manifests,
    data.kubectl_path_documents.services["payments"].manifests,
    data.kubectl_path_documents.ingress.manifests,
    data.kubectl_path_documents.trafficgen.manifests
  )
  yaml_body = each.value
  depends_on = [kubernetes_namespace.eshop]
}
