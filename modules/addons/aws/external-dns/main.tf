resource "aws_route53_zone" "cluster" {
  count  = var.external_dns_enabled == true ? 1 : 0
  name   = "${var.cluster_name}.${var.dns_zone}"
  tags   = merge(var.tags, {
          Name = "${var.cluster_name}.${var.dns_zone}"
  })
}

data "aws_route53_zone" "shared" {
  count  = local.shared_zone && var.external_dns_enabled == true ? 1 : 0
  name   = var.dns_zone
}

resource "aws_route53_record" "ns" {
  count   = local.shared_zone && var.external_dns_enabled == true ? 1 : 0
  zone_id = data.aws_route53_zone.shared[0].zone_id
  name    = aws_route53_zone.cluster[0].name
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.cluster[0].name_servers
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = var.k8s_host
    cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
    token                  = var.k8s_client_token
  }
}

module "external_dns_helm" {
  source = "lablabs/eks-external-dns/aws"
  enabled           = var.external_dns_enabled
  argo_enabled      = false
  argo_helm_enabled = false

  cluster_identity_oidc_issuer     = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  cluster_identity_oidc_issuer_arn = var.oidc_provider_arn
  irsa_tags                        = var.tags

  helm_release_name       = "external-dns"
  helm_repo_url           = "https://charts.bitnami.com/bitnami"
  helm_chart_name         = "external-dns"
  helm_create_namespace   = true
  namespace               = "external-dns"
  helm_timeout            = "900"
  helm_wait               = true

  values = yamlencode({
    "policy": "upsert-only"
    "registry" : "txt"
    "txtOwnerId" : var.cluster_name
    "domainFilters": [aws_route53_zone.cluster[0].name]
    "sources": [var.sources]
    "annotationFilter": var.annotation_filter
    "labelFilter": var.label_filter
    "provider" : "aws"
    "interval" : var.interval
  })

}


