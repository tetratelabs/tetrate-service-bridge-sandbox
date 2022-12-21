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

data "kubectl_path_documents" "tsb_dashboards" {
  for_each = fileset("${path.module}/dashboards", "*.json")
  pattern  = "${path.module}/manifests/dashboard-configmap.yaml.tmpl"
  vars     = {
    name           = replace(replace(each.value, ".json", ""), "_", "-")
    namespace      = var.namespace
    dashboard_key  = each.value
    dashboard_json = indent(4, file("${path.module}/dashboards/${each.value}"))
  }
}

resource "kubectl_manifest" "tsb_dashboards" {
  for_each = fileset("${path.module}/dashboards", "*.json")
  yaml_body  = data.kubectl_path_documents.tsb_dashboards[each.value].documents[0]
}

resource "helm_release" "grafana" {
  depends_on       = [kubectl_manifest.tsb_dashboards]
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  create_namespace = true
  namespace        = var.namespace
  timeout          = 900

  values = [file("${path.module}/manifests/grafana-values.yaml")]

  set {
    name  = "adminPassword"
    value = var.admin_password
  }
}
