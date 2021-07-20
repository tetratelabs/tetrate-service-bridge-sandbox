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

resource "kubectl_server_version" "current" {}

# this is solely for demo purposes, to keep the tctl commands execution on remote jumpbox to decouple from the localhost as dependency
# kubectl however to be managed by terraform resource locally

resource "kubernetes_namespace" "tsb" {
  metadata {
    name = "tsb"
  }
  lifecycle {
    ignore_changes = [metadata]
  }

}
resource "null_resource" "tctl_managementplane" {
  connection {
    host        = var.jumpbox_host
    type        = "ssh"
    agent       = false
    user        = var.jumpbox_username
    private_key = var.jumpbox_pkey
  }
  provisioner "remote-exec" {

    inline = [
      "mkdir ~/tctl",
      "/usr/bin/env tctl install manifest management-plane-operator --registry ${var.registry}  > ~/tctl/managementplaneoperator.yaml"
    ]
  }

  # file-remote is not supported yet, https://github.com/hashicorp/terraform/issues/3379
  provisioner "local-exec" {
    command = "scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i ${var.name_prefix}-${var.jumpbox_username}.pem  ${var.jumpbox_username}@${var.jumpbox_host}:~/tctl/managementplaneoperator.yaml ${path.module}/manifests/tctl/managementplaneoperator.yaml"
  }
}


data "kubectl_path_documents" "managementplaneoperator" {
  pattern          = "${path.module}/manifests/tctl/managementplaneoperator.yaml"
  disable_template = true
}

resource "kubectl_manifest" "managementplaneoperator" {
  count     = length(data.kubectl_path_documents.managementplaneoperator.documents)
  yaml_body = element(data.kubectl_path_documents.managementplaneoperator.documents, count.index)
}

data "kubectl_path_documents" "tsbservercert" {
  pattern          = "${path.module}/manifests/tsb-server-crt.yaml"
  disable_template = true
}

resource "kubectl_manifest" "tsbservercert" {
  count      = length(data.kubectl_path_documents.tsbservercert.documents)
  yaml_body  = element(data.kubectl_path_documents.tsbservercert.documents, count.index)
  depends_on = [kubernetes_namespace.tsb]
}

data "template_file" "managementplanesecrets_sh" {
  template = file("${path.module}/manifests/tctl-management-plane-secrets.sh.tmpl")
  vars = {
    kubeconfig       = "${var.cluster_name}-kubeconfig"
    tsbadminpassword = var.tctl_password
  }
  depends_on = [kubectl_manifest.tsbservercert]
}

resource "null_resource" "tctl_managementplanesecrets" {

  connection {
    host        = var.jumpbox_host
    type        = "ssh"
    agent       = false
    user        = var.jumpbox_username
    private_key = var.jumpbox_pkey
  }

  provisioner "file" {
    source      = "${var.cluster_name}-kubeconfig"
    destination = "~/${var.cluster_name}-kubeconfig"
  }

  provisioner "file" {
    content     = data.template_file.managementplanesecrets_sh.rendered
    destination = "~/tctl/tctl-management-plane-secrets.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sh ~/tctl/tctl-management-plane-secrets.sh"
    ]
  }

  # file-remote is not supported yet, https://github.com/hashicorp/terraform/issues/3379
  provisioner "local-exec" {
    command = "scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i ${var.name_prefix}-${var.jumpbox_username}.pem  ${var.jumpbox_username}@${var.jumpbox_host}:~/tctl/managementplanesecrets.yaml ${path.module}/manifests/tctl/managementplanesecrets.yaml"
  }
  depends_on = [data.template_file.managementplanesecrets_sh]

}

data "kubectl_path_documents" "managementplanesecrets" {
  pattern          = "${path.module}/manifests/tctl/managementplanesecrets.yaml"
  disable_template = true
  #depends_on       = [null_resource.tctl_managementplanesecrets]
}

resource "kubectl_manifest" "managementplanesecrets" {
  count      = length(data.kubectl_path_documents.managementplanesecrets.documents)
  yaml_body  = element(data.kubectl_path_documents.managementplanesecrets.documents, count.index)
  depends_on = [null_resource.tctl_managementplanesecrets]
}

data "kubernetes_service" "es" {
  metadata {
    name      = "tsb-es-http"
    namespace = "elastic-system"
  }
  depends_on = [kubectl_manifest.managementplanesecrets]
}

data "template_file" "managementplane" {
  template = file("${path.module}/manifests/managementplane.yaml.tmpl")
  vars = {
    es_host  = data.kubernetes_service.es.status[0].load_balancer[0].ingress[0].ip
    registry = var.registry
  }
  depends_on = [kubectl_manifest.managementplanesecrets]
}

resource "kubectl_manifest" "managementplane" {
  count      = 1
  yaml_body  = data.template_file.managementplane.rendered
  depends_on = [null_resource.tctl_managementplanesecrets]
}

data "kubernetes_service" "tsb" {
  metadata {
    name      = "envoy"
    namespace = "tsb"
  }
  depends_on = [kubectl_manifest.managementplane]
}

data "kubernetes_secret" "es_password" {
  metadata {
    name      = "tsb-es-elastic-user"
    namespace = "elastic-system"
  }
  depends_on = [kubectl_manifest.managementplane]
}

data "kubernetes_secret" "es_cacert" {
  metadata {
    name      = "tsb-es-http-ca-internal"
    namespace = "elastic-system"
  }
  depends_on = [kubectl_manifest.managementplane]
}
