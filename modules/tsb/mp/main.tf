provider "kubernetes" {
  host                    = var.k8s_host
  cluster_ca_certificate  = base64decode(var.k8s_cluster_ca_certificate)
  client_certificate      = base64decode(var.k8s_client_certificate)
  client_key              = base64decode(var.k8s_client_key)
}

provider "kubectl" {
  host                    = var.k8s_host
  cluster_ca_certificate  = base64decode(var.k8s_cluster_ca_certificate)
  client_certificate      = base64decode(var.k8s_client_certificate)
  client_key              = base64decode(var.k8s_client_key)
  load_config_file        = false
}

resource "kubectl_server_version" "current" { }

data "kubectl_path_documents" "certmanager" {
    pattern = "${path.module}/manifests/cert-manager.yaml"
    disable_template = true
}

resource "kubectl_manifest" "certmanager" {
    count     = length(data.kubectl_path_documents.certmanager.documents)
    yaml_body = element(data.kubectl_path_documents.certmanager.documents, count.index)
}

resource "null_resource" "tctl_managementplane" {

  provisioner "local-exec" {

    command = "/usr/bin/env tctl install manifest management-plane-operator --registry $REGISTRY  > $PATH_MODULE/manifests/tctl/managementplaneoperator.yaml"

    environment = {
      REGISTRY        = var.registry
      PATH_MODULE     = path.module
    }
  }
}

data "kubectl_path_documents" "managementplaneoperator" {
    pattern = "${path.module}/manifests/tctl/managementplaneoperator.yaml"
    disable_template = true
}

resource "kubectl_manifest" "managementplaneoperator" {
    count     = length(data.kubectl_path_documents.managementplaneoperator.documents)
    yaml_body = element(data.kubectl_path_documents.managementplaneoperator.documents, count.index)
}

data "kubectl_path_documents" "tsbservercert" {
    pattern = "${path.module}/manifests/tsb-server-crt.yaml"
    disable_template = true
}

resource "kubectl_manifest" "tsbservercert" {
    count     = length(data.kubectl_path_documents.tsbservercert.documents)
    yaml_body = element(data.kubectl_path_documents.tsbservercert.documents, count.index)
}

resource "null_resource" "tctl_managementplanesecrets" {

  provisioner "local-exec" {

    command = "${path.module}/manifests/tctl-management-plane-secrets.sh"

    environment = {
      PATH_MODULE      = path.module
      KUBECONFIG       = "${var.cluster_name}-kubeconfig"
      TSBADMINPASSWORD = var.tctl_password
    }
  }
}

data "kubectl_path_documents" "managementplanesecrets" {
    pattern = "${path.module}/manifests/tctl/managementplanesecrets.yaml"
    disable_template = true
}

resource "kubectl_manifest" "managementplanesecrets" {
    count     = length(data.kubectl_path_documents.managementplanesecrets.documents)
    yaml_body = element(data.kubectl_path_documents.managementplanesecrets.documents, count.index)
}

data "kubernetes_service" "es" {
  metadata {
    name = "tsb-es-http"
    namespace = "elastic-system"
  }
}

data "template_file" "managementplane" {
  template = file("${path.module}/manifests/managementplane.yaml.tmpl")
  vars = {
    es_host     = data.kubernetes_service.es.status[0].load_balancer[0].ingress[0].ip
    registry    = var.registry
  }
}

resource "kubectl_manifest" "managementplane" {
    count     = length(data.kubectl_path_documents.managementplanesecrets.documents)
    yaml_body = data.template_file.managementplane.rendered
} 

data "kubernetes_service" "tsb" {
  metadata {
    name = "envoy"
    namespace = "tsb"
  }
  depends_on = [ kubectl_manifest.managementplane ]
}

data "kubernetes_secret" "es_password" {
  metadata {
    name = "tsb-es-elastic-user"
    namespace = "elastic-system"
  }
  depends_on = [ kubectl_manifest.managementplane ]
}

data "kubernetes_secret" "es_cacert" {
  metadata {
    name = "tsb-es-http-ca-internal"
    namespace = "elastic-system"
  }
  depends_on = [ kubectl_manifest.managementplane ]
}
