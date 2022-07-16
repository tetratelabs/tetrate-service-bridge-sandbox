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

resource "null_resource" "jumpbox_tctl" {
  connection {
    host        = var.jumpbox_host
    type        = "ssh"
    agent       = false
    user        = var.jumpbox_username
    private_key = var.jumpbox_pkey
  }
  provisioner "file" {
    content = templatefile("${path.module}/manifests/tsb/cluster.yaml.tmpl", {
      cluster_name    = var.cluster_name
      tsb_org         = var.tsb_org
      tier1_cluster   = var.tier1_cluster
      locality_region = var.locality_region
    })
    destination = "${var.cluster_name}-cluster.yaml"
  }
  provisioner "file" {
    content = templatefile("${path.module}/manifests/tctl/tctl-controlplane.sh.tmpl", {
      cluster_name = var.cluster_name
      tsb_mp_host  = var.tsb_mp_host
      tsb_org      = var.tsb_org
      tsb_tenant   = "tetrate"
      tsb_username = var.tsb_username
      tsb_password = var.tsb_password
    })
    destination = "${var.cluster_name}-tctl-controlplane.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sh ${var.cluster_name}-tctl-controlplane.sh"
    ]
  }

  # file-remote is not supported yet, https://github.com/hashicorp/terraform/issues/3379
  provisioner "local-exec" {
    command = "scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i ${var.name_prefix}-${var.cloud}-${var.jumpbox_username}.pem  ${var.jumpbox_username}@${var.jumpbox_host}:${var.cluster_name}-service-account.jwk ${var.cluster_name}-service-account.jwk"
  }
}

data "local_file" "service_account" {
  filename   = "${var.cluster_name}-service-account.jwk"
  depends_on = [null_resource.jumpbox_tctl]
}
resource "helm_release" "controlplane" {
  name                = "controlplane"
  repository          = "https://dl.cloudsmith.io/basic/tetrate/tsb-helm/helm/charts/"
  chart               = "controlplane"
  version             = var.tsb_helm_version
  create_namespace    = true
  namespace           = "istio-system"
  timeout             = 900
  repository_username = var.tsb_helm_username
  repository_password = var.tsb_helm_password

  values = [templatefile("${path.module}/manifests/tsb/controlplane-values.yaml.tmpl", {
    registry                  = var.registry
    tsb_version               = var.tsb_version
    tsb_fqdn                  = var.tsb_fqdn
    cluster_name              = var.cluster_name
    serviceaccount_clusterfqn = "organizations/${var.tsb_org}/clusters/${var.cluster_name}"
    serviceaccount_jwk        = data.local_file.service_account.content
    es_host                   = var.es_host
    es_username               = var.es_username
    es_password               = var.es_password
  })]

  set {
    name  = "secrets.tsb.cacert"
    value = var.tsb_cacert
  }
  set {
    name  = "secrets.xcp.rootca"
    value = var.tsb_cacert
  }

  set {
    name  = "secrets.elasticsearch.cacert"
    value = var.es_cacert
  }
}

resource "kubernetes_secret_v1" "cacerts" {
  metadata {
    name      = "cacerts"
    namespace = "istio-system"
    annotations = {
      clustername = var.cluster_name
    }
  }

  data = {
    "ca-cert.pem"    = var.istiod_cacerts_tls_crt
    "ca-key.pem"     = var.istiod_cacerts_tls_key
    "root-cert.pem"  = var.tsb_cacert
    "cert-chain.pem" = var.istiod_cacerts_tls_crt
  }

  type       = "kubernetes.io/generic"
  depends_on = [helm_release.controlplane]
}
resource "helm_release" "dataplane" {
  name                = "dataplane"
  repository          = "https://dl.cloudsmith.io/basic/tetrate/tsb-helm/helm/charts/"
  chart               = "dataplane"
  version             = var.tsb_helm_version
  create_namespace    = true
  namespace           = "istio-gateway"
  timeout             = 900
  repository_username = var.tsb_helm_username
  repository_password = var.tsb_helm_password

  set {
    name  = "image.registry"
    value = var.registry
  }

  set {
    name  = "image.tag"
    value = var.tsb_version
  }
}

resource "kubernetes_namespace" "gitops-tier1" {
  count = var.tier1_cluster == true ? 1 : 0
  metadata {
    labels = {
      istio-injection = "enabled"
    }
    name = "gitops-tier1"
  }
}
