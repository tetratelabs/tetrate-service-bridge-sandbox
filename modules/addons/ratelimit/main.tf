provider "kubectl" {
  host                   = var.k8s_host
  cluster_ca_certificate = base64decode(var.k8s_cluster_ca_certificate)
  token                  = var.k8s_client_token
  load_config_file       = false
}

data "external" "redis_image" {
  count   = var.enabled ? 1 : 0
  program = ["bash", "${path.module}/redis-image.sh"]
  query = {
    "tsb_version" = var.tsb_version
    "registry"    = var.registry
  }
}

data "kubectl_path_documents" "ratelimit" {
  count   = var.enabled ? 1 : 0
  pattern = "${path.module}/manifests/ratelimit-redis.yaml.tmpl"
  vars = {
    password  = var.password
    image     = data.external.redis_image[0].result.image
  }
}

resource "kubectl_manifest" "ratelimit" {
  count     = var.enabled ? length(data.kubectl_path_documents.ratelimit[0].documents) : 0
  yaml_body = element(data.kubectl_path_documents.ratelimit[0].documents, count.index)
}

resource "kubernetes_secret" "redis_password" {
  count = var.enabled ? 1 : 0
  metadata {
    name      = "redis-credentials"
    namespace = "istio-system"
  }

  data = {
    REDIS_AUTH = var.password
  }
}
