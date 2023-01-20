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

  set {
    name  = "policy"
    value = "upsert-only"
  }

  set {
    name  = "registry"
    value = "txt"
  }

  set {
    name  = "txtOwnerId"
    value = var.cluster_name
  }

  # Since we are enabling the Istio Gateway source, it is important to set this filter
  # so we don't create DNS records for any random or internal hostnames defined in
  # the TSB IngressGateways.
  set {
    name  = "domainFilters"
    value = "{${var.dns_zone}}"
  }

  set {
    name  = "sources"
    value = "{service,ingress,istio-gateway}"
  }

  values = [templatefile("${path.module}/manifests/values-${var.dns_provider}.yaml.tmpl", {
    google_project             = var.google_project
    google_service_account_key = indent(4, var.google_service_account_key)
  })]
}
