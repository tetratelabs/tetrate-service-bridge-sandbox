provider "kubernetes" {
  host                   = var.k8s_host
  cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
  client_certificate     = base64decode(var.k8s_client_certificate)
  client_key             = base64decode(var.k8s_client_key)
}
provider "kubectl" {
  host                   = var.k8s_host
  cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
  client_certificate     = base64decode(var.k8s_client_certificate)
  client_key             = base64decode(var.k8s_client_key)
  load_config_file       = false
}


data "template_file" "cluster" {
  template = file("${path.module}/manifests/cluster.yaml.tmpl")
  vars = {
    cluster_name = var.cluster_name
    organization = "tetrate"
  }
}

data "template_file" "controlplane" {
  template = file("${path.module}/manifests/controlplane.yaml.tmpl")
  vars = {
    es_host      = var.es_host
    registry     = var.registry
    tctl_host    = var.tctl_host
    cluster_name = var.cluster_name
  }
}

data "template_file" "clusteroperators" {
  template = file("${path.module}/manifests/tctl-control-plane.sh.tmpl")
  vars = {
    mp_cluster_name = var.mp_cluster_name
    cluster_name    = var.cluster_name
    tctl_host       = var.tctl_host
    tctl_username   = var.tctl_username
    tctl_password   = var.tctl_password
    tctl_org        = "tetrate"
    tctl_tenant     = "tetrate"
    registry        = var.registry
    es_username     = "elastic"
    es_password     = var.es_password
    es_cacert       = base64encode(var.es_cacert)
  }
}

resource "null_resource" "tctl_clusteroperators" {
  connection {
    host        = var.jumpbox_host
    type        = "ssh"
    agent       = false
    user        = var.jumpbox_username
    private_key = var.jumpbox_pkey
  }
  provisioner "file" {
    content     = data.template_file.cluster.rendered
    destination = "~/tctl/${var.cluster_name}-cluster.yaml"
  }

  provisioner "file" {
    content     = data.template_file.controlplane.rendered
    destination = "~/tctl/${var.cluster_name}-controlplane.yaml"
  }

  provisioner "file" {
    content     = data.template_file.clusteroperators.rendered
    destination = "~/tctl/${var.cluster_name}-tctl-control-plane.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sh ~/tctl/${var.cluster_name}-tctl-control-plane.sh"
    ]
  }

  # file-remote is not supported yet, https://github.com/hashicorp/terraform/issues/3379
  provisioner "local-exec" {
    command = "scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i ${var.name_prefix}-${var.jumpbox_username}.pem  ${var.jumpbox_username}@${var.jumpbox_host}:~/tctl/${var.cluster_name}-*.yaml ${path.module}/manifests/tctl/"
  }
  depends_on = [data.template_file.cluster, data.template_file.controlplane]
}
data "kubectl_path_documents" "clusteroperators" {
  pattern          = "${path.module}/manifests/tctl/${var.cluster_name}-clusteroperators.yaml"
  disable_template = true
}

resource "kubectl_manifest" "clusteroperators" {
  count     = length(data.kubectl_path_documents.clusteroperators.documents)
  yaml_body = element(data.kubectl_path_documents.clusteroperators.documents, count.index)
}

data "kubectl_path_documents" "controlplanesecrets" {
  pattern          = "${path.module}/manifests/tctl/${var.cluster_name}-controlplane-secrets.yaml"
  disable_template = true
}

resource "kubectl_manifest" "controlplanesecrets" {
  count      = length(data.kubectl_path_documents.controlplanesecrets.documents)
  yaml_body  = element(data.kubectl_path_documents.controlplanesecrets.documents, count.index)
  depends_on = [kubectl_manifest.clusteroperators]
}


data "kubectl_path_documents" "controlplane" {
  pattern          = "${path.module}/manifests/tctl/${var.cluster_name}-controlplane.yaml"
  disable_template = true
}

resource "kubectl_manifest" "controlplane" {
  count      = length(data.kubectl_path_documents.controlplane.documents)
  yaml_body  = element(data.kubectl_path_documents.controlplane.documents, count.index)
  depends_on = [kubectl_manifest.controlplanesecrets]
}


