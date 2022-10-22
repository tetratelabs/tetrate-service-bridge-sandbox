resource "kubernetes_namespace" "eshop_config" {
  metadata {
    name = "eshop-config"
  }
}

data "kubectl_path_documents" "workspaces" {
  pattern = "${path.module}/manifests/tsb/workspaces.yaml"
  disable_template = true
}

resource "kubectl_manifest" "workspaces" {
  count      = length(data.kubectl_path_documents.workspaces.documents)
  yaml_body  = element(data.kubectl_path_documents.workspaces.documents, count.index)
  depends_on = [kubernetes_namespace.eshop_config]
}

data "kubectl_path_documents" "teams" {
  pattern = "${path.module}/manifests/tsb/teams.yaml"
  vars    = {
    tenant_owner   = var.tenant_owner
    eshop_owner    = var.eshop_owner
    payments_owner = var.payments_owner
  }
}

resource "kubectl_manifest" "teams" {
  count      = length(data.kubectl_path_documents.teams.documents)
  yaml_body  = element(data.kubectl_path_documents.teams.documents, count.index)
  depends_on = [kubernetes_namespace.eshop_config]
}

data "kubectl_path_documents" "ingress_config" {
  pattern = "${path.module}/manifests/tsb/ingress.yaml"
  vars    = {
    eshop_host     = var.eshop_host
    payments_host  = var.payments_host
  }
}

resource "kubectl_manifest" "ingress_config" {
  count      = length(data.kubectl_path_documents.ingress_config.documents)
  yaml_body  = element(data.kubectl_path_documents.ingress_config.documents, count.index)
  depends_on = [kubectl_manifest.workspaces]
}

data "kubectl_path_documents" "permissions" {
  pattern = "${path.module}/manifests/tsb/permissions.yaml"
  vars    = {
    tenant_owner   = var.tenant_owner
    eshop_owner    = var.eshop_owner
    payments_owner = var.payments_owner
  }
}

resource "kubectl_manifest" "permissions" {
  count      = length(data.kubectl_path_documents.permissions.documents)
  yaml_body  = element(data.kubectl_path_documents.permissions.documents, count.index)
  depends_on = [kubectl_manifest.teams, kubectl_manifest.workspaces]
}
