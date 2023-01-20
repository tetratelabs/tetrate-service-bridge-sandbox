provider "helm" {
  kubernetes {
    host                   = var.k8s_host
    cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
    token                  = var.k8s_client_token
  }
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "external-dns"
  create_namespace = true
  namespace        = "external-dns"
  timeout          = 900

  values = [templatefile("${path.module}/manifests/values-${var.dns_provider}.yaml.tmpl", {
    dns_zone                   = var.dns_zone
    dns_owner_id               = var.cluster_name
    google_project             = var.google_project
    google_service_account_key = indent(4, var.google_service_account_key)
  })]
}
