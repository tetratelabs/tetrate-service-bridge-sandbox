resource "google_service_account" "external_dns" {
  count        = var.external_dns_enabled == true ? 1 : 0
  project      = var.project_id
  account_id   = "${var.cluster_name}-external-dns"
}

resource "google_dns_managed_zone" "cluster" {
  count      = var.external_dns_enabled == true ? 1 : 0
  project    = var.project_id
  name       = "${var.cluster_name}-${local.zone_name}"
  dns_name   = "${var.cluster_name}.${local.dns_name}."
}

data "google_dns_managed_zone" "shared" {
  count        = local.shared_zone && var.external_dns_enabled == true ? 1 : 0
  project      = "dns-terraform-sandbox"
  name         = local.zone_name
}

resource "google_dns_record_set" "ns" {
  count        = local.shared_zone && var.external_dns_enabled == true ? 1 : 0
  managed_zone = data.google_dns_managed_zone.shared[0].name
  project      = "dns-terraform-sandbox"
  name         = google_dns_managed_zone.cluster[0].dns_name
  type         = "NS"
  ttl          = 300

  rrdatas = google_dns_managed_zone.cluster[0].name_servers
}

resource "google_project_iam_member" "dns_admin" {
  count     = var.external_dns_enabled == true ? 1 : 0
  project   = var.project_id
  role      = "roles/dns.admin"
  member    = "serviceAccount:${google_service_account.external_dns[0].email}"
}

resource "google_service_account_key" "external_dns_key" {
  count              = var.external_dns_enabled == true ? 1 : 0
  service_account_id = google_service_account.external_dns[0].name
}

provider "helm" {
  kubernetes {
    host                   = var.k8s_host
    cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
    token                  = var.k8s_client_token
  }
}

resource "helm_release" "external_dns" {
  count            = var.external_dns_enabled == true ? 1 : 0
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
    value = "{${google_dns_managed_zone.cluster[0].dns_name}}"
  }

  set {
    name  = "sources"
    value = "{${var.sources}}"
  }

  set {
    name  = "annotationFilter"
    value = var.annotation_filter
  }

  set {
    name  = "labelFilter"
    value = var.label_filter
  }

  values = [templatefile("${path.module}/manifests/values.yaml.tmpl", {
    google_project             = var.project_id
    google_service_account_key = indent(4, base64decode(google_service_account_key.external_dns_key[0].private_key))
  })]
}