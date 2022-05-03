provider "helm" {
  kubernetes {
    host                   = var.k8s_host
    cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
    client_certificate     = base64decode(var.k8s_client_certificate)
    client_key             = base64decode(var.k8s_client_key)
  }
}

provider "kubectl" {
  host                   = var.k8s_host
  cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
  client_certificate     = base64decode(var.k8s_client_certificate)
  client_key             = base64decode(var.k8s_client_key)
  load_config_file       = false
}

provider "kubernetes" {
  host                   = var.k8s_host
  cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
  client_certificate     = base64decode(var.k8s_client_certificate)
  client_key             = base64decode(var.k8s_client_key)
}

data "template_file" "cluster" {
  template = file("${path.module}/manifests/tsb/cluster.yaml.tmpl")
  vars = {
    cluster_name = var.cluster_name
    tsb_org      = var.tsb_org
  }
}

data "template_file" "tctl_controlplane" {
  template = file("${path.module}/manifests/tctl/tctl-controlplane.sh.tmpl")
  vars = {
    cluster_name = var.cluster_name
    tsb_mp_host  = var.tsb_mp_host
    tsb_org      = var.tsb_org
    tsb_tenant   = "tetrate"
    tsb_username = var.tsb_username
    tsb_password = var.tsb_password
  }
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
    content     = data.template_file.cluster.rendered
    destination = "${var.cluster_name}-cluster.yaml"
  }
  provisioner "file" {
    content     = data.template_file.tctl_controlplane.rendered
    destination = "${var.cluster_name}-tctl-controlplane.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sh ${var.cluster_name}-tctl-controlplane.sh"
    ]
  }

  # file-remote is not supported yet, https://github.com/hashicorp/terraform/issues/3379
  provisioner "local-exec" {
    command = "scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i ${var.name_prefix}-${var.jumpbox_username}.pem  ${var.jumpbox_username}@${var.jumpbox_host}:${var.cluster_name}-service-account.jwk ${var.cluster_name}-service-account.jwk"
  }

  depends_on = [data.template_file.cluster, data.template_file.tctl_controlplane]
}

data "template_file" "controlplane_values" {
  template = file("${path.module}/manifests/tsb/controlplane-values.yaml.tmpl")
  vars = {
    registry     = var.registry
    tsb_version  = var.tsb_version
    tsb_fqdn     = var.tsb_fqdn
    cluster_name = var.cluster_name
    #es
    es_host     = var.es_host
    es_username = var.es_username
    es_password = var.es_password
  }
}
data "local_file" "service_account" {
  filename = "${var.cluster_name}-service-account.jwk"
}

resource "helm_release" "controlplane" {
  name                = "controlplane"
  repository          = "https://dl.cloudsmith.io/PcTzkIaPWoQlH4Tj/tetrate/helm-internal/helm/charts"
  chart               = "controlplane"
  version             = "1.5.0-dev"
  create_namespace    = true
  namespace           = "istio-system"
  timeout             = 900
  repository_username = var.image-sync_username
  repository_password = var.image-sync_apikey

  values = [data.template_file.controlplane_values.rendered]

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

  set {
    name  = "secrets.clusterServiceAccount.clusterFQN"
    value = "organizations/${var.tsb_org}t/clusters/${var.cluster_name}"
  }

  set {
    name = "secrets.clusterServiceAccount.JWK"
    #value = "test123"
    value = tostring(data.local_file.service_account.content)
  }
}

resource "helm_release" "dataplane" {
  name                = "dataplane"
  repository          = "https://dl.cloudsmith.io/PcTzkIaPWoQlH4Tj/tetrate/helm-internal/helm/charts"
  chart               = "dataplane"
  version             = "1.5.0-dev"
  create_namespace    = true
  namespace           = "istio-gateway"
  timeout             = 900
  repository_username = var.image-sync_username
  repository_password = var.image-sync_apikey

  set {
    name  = "image.registry"
    value = var.registry
  }

  set {
    name  = "image.tag"
    value = var.tsb_version
  }
}
