resource "azurerm_role_assignment" "external_dns" {
  count                            = var.external_dns_enabled == true ? 1 : 0
  scope                            = var.resource_group_id
  role_definition_name             = "DNS Zone Contributor"
  principal_id                     = var.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_dns_zone" "cluster" {
  count               = var.external_dns_enabled == true ? 1 : 0
  resource_group_name = var.resource_group_name
  name                = "${var.cluster_name}.${local.dns_name}"
  tags                = merge(var.tags, {
          Name = "${var.cluster_name}.${local.dns_name}"
  })
}

data "azurerm_dns_zone" "shared" {
  count               = local.shared_zone && var.external_dns_enabled == true ? 1 : 0
  resource_group_name = "dns-terraform-sandbox"
  name                = var.dns_zone
}

resource "azurerm_dns_ns_record" "ns" {
  count               = local.shared_zone && var.external_dns_enabled == true ? 1 : 0
  name                = "${var.cluster_name}"
  zone_name           = data.azurerm_dns_zone.shared[0].name
  resource_group_name = "dns-terraform-sandbox"
  ttl                 = 300
  records             = azurerm_dns_zone.cluster[0].name_servers
  tags                = merge(var.tags, {
          Name = "${var.cluster_name}.${local.dns_name}"
  })
}

data "azurerm_client_config" "this" {}

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
    value = "{${azurerm_dns_zone.cluster[0].name}}"
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

  set {
    name  = "interval"
    value = var.interval
  }

  values = [templatefile("${path.module}/manifests/values.yaml.tmpl", {
    resource_group             = var.resource_group_name
    tenant_id                  = data.azurerm_client_config.this.tenant_id
    subscription_id            = data.azurerm_client_config.this.subscription_id
  })]
}