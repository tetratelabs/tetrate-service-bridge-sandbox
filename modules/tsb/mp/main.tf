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

resource "kubernetes_namespace" "tsb" {
  metadata {
    name = "tsb"
  }
  lifecycle {
    ignore_changes = [metadata]
  }
}
}
data "kubernetes_secret" "selfsigned_ca" {
  metadata {
    name      = "selfsigned-ca"
    namespace = "cert-manager"
  }
}

data "kubernetes_secret" "tsb_server_cert" {
  metadata {
    name      = "tsb-server-cert"
    namespace = "cert-manager"
  }

}

data "kubernetes_secret" "es_password" {
  metadata {
    name      = "tsb-es-elastic-user"
    namespace = "elastic-system"
  }
}

data "kubernetes_secret" "es_cacert" {
  metadata {
    name      = "tsb-es-http-ca-internal"
    namespace = "elastic-system"
  }
}


data "kubernetes_service" "es" {
  metadata {
    name      = "tsb-es-http"
    namespace = "elastic-system"
  }
}

data "template_file" "managementplane_values" {
  template = file("${path.module}/manifests/tsb/managementplane-values.yaml.tmpl")

  vars = {
    #tsb
    tsb_version  = var.tsb_version
    registry     = var.registry
    tsb_password = var.tsb_password
    tsb_org      = var.tsb_org
    #eck
    es_host     = data.kubernetes_service.es.status[0].load_balancer[0].ingress[0].ip
    es_username = "elastic"
    es_password = data.kubernetes_secret.es_password.data["elastic"]
    # demo db profile
    db_username = "tsb"
    db_password = "tsb-postgres-password"
    # demo ldap profile
    ldap_binddn       = "cn=admin,dc=tetrate,dc=io"
    ldap_bindpassword = "admin"
  }
}


resource "helm_release" "managementplane" {
  name                = "managementplane"
  repository          = "https://dl.cloudsmith.io/PcTzkIaPWoQlH4Tj/tetrate/helm-internal/helm/charts"
  chart               = "managementplane"
  version             = var.tsb_helm_version
  namespace           = "tsb"
  timeout             = 900
  repository_username = var.image-sync_username
  repository_password = var.image-sync_apikey

  values = [data.template_file.managementplane_values.rendered]
  set {
    name  = "secrets.tsb.cert"
    value = data.kubernetes_secret.tsb_server_cert.data["tls.crt"]
  }
  set {
    name  = "secrets.tsb.key"
    value = data.kubernetes_secret.tsb_server_cert.data["tls.key"]
  }

  set {
    name  = "secrets.xcp.rootca"
    value = data.kubernetes_secret.selfsigned_ca.data["tls.crt"]
  }
  set {
    name  = "secrets.xcp.rootcakey"
    value = data.kubernetes_secret.selfsigned_ca.data["tls.key"]
  }

  set {
    name  = "secrets.elasticsearch.cacert"
    value = data.kubernetes_secret.es_cacert.data["tls.crt"]

  }

}

resource "time_sleep" "wait_90_seconds" {
  depends_on      = [helm_release.managementplane]
  create_duration = "90s"
}

resource "null_resource" "jumpbox_kubectl" {
  connection {
    host        = var.jumpbox_host
    type        = "ssh"
    agent       = false
    user        = var.jumpbox_username
    private_key = var.jumpbox_pkey
  }

  provisioner "file" {
    source      = "${var.cluster_name}-kubeconfig"
    destination = "${var.cluster_name}-kubeconfig"
  }
  provisioner "remote-exec" {

    inline = [
      "kubectl --kubeconfig ${var.cluster_name}-kubeconfig create job -n tsb teamsync-bootstrap --from=cronjob/teamsync"
    ]
  }

  depends_on = [time_sleep.wait_90_seconds]
}

data "kubernetes_service" "tsb" {
  metadata {
    name      = "envoy"
    namespace = "tsb"
  }
  depends_on = [time_sleep.wait_90_seconds]
}
