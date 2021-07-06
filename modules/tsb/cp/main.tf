provider "kubectl" {
  host                    = var.k8s_host
  cluster_ca_certificate  = base64decode(var.k8s_cluster_ca_certificate)
  client_certificate      = base64decode(var.k8s_client_certificate)
  client_key              = base64decode(var.k8s_client_key)
  load_config_file        = false
}


data "template_file" "cluster" {
  template = file("${path.module}/manifests/tctl/cluster.yaml.tmpl")
  vars = {
    es_host      = var.es_host
    registry     = var.registry
    tctl_host    = var.tctl_host
    cluster_name = var.cluster_name
  }
}

resource "local_file" "cluster" {
    content           = data.template_file.cluster.rendered
    filename          = "${path.module}/manifests/tctl/${var.cluster_name}.yaml"
}

resource "null_resource" "tctl_clusteroperators" {

  provisioner "local-exec" {

    command = <<EOT
      /usr/bin/env tctl config clusters set default --bridge-address $TCTL_HOST:8443
      /usr/bin/env tctl config profiles set-current default
      /usr/bin/env tctl login --org tetrate --username admin --password admin $TCTL_HOST --tenant tetrate
      /usr/bin/env tctl apply -f $PATH_MODULE/manifests/tctl/$CLUSTER_NAME.yaml
      /usr/bin/env tctl install manifest cluster-operators --registry $REGISTRY  > $PATH_MODULE/manifests/tctl/clusteroperators.yaml
      EOT
    environment = {
      REGISTRY        = var.registry
      PATH_MODULE     = path.module
      TCTL_HOST       = var.tctl_host
      ES_PASSWORD     = var.es_password
      ES_CACERT       = var.es_cacert
      CLUSTER_NAME    = var.cluster_name
    }
  }
  depends_on = [ local_file.cluster ]
}


data "kubectl_path_documents" "clusteroperators" {
    pattern = "${path.module}/manifests/tctl/clusteroperators.yaml"
    disable_template = true
    depends_on = [ null_resource.tctl_clusteroperators ]
}

resource "kubectl_manifest" "clusteroperators" {
    count     = length(data.kubectl_path_documents.clusteroperators.documents)
    yaml_body = element(data.kubectl_path_documents.clusteroperators.documents, count.index)
    depends_on = [ null_resource.tctl_clusteroperators ]
}

