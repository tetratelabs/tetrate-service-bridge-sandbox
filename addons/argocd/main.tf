data "terraform_remote_state" "aws" {
  count   = length(var.aws_k8s_regions)
  backend = "local"
  config = {
    path = "../../infra/aws/terraform.tfstate.d/aws-${count.index}-${var.aws_k8s_regions[count.index]}/terraform.tfstate"
  }
}

data "terraform_remote_state" "azure" {
  count   = length(var.azure_k8s_regions)
  backend = "local"
  config = {
    path = "../../infra/azure/terraform.tfstate.d/azure-${count.index}-${var.azure_k8s_regions[count.index]}/terraform.tfstate"
  }
}

data "terraform_remote_state" "gcp" {
  count   = length(var.gcp_k8s_regions)
  backend = "local"
  config = {
    path = "../../infra/gcp/terraform.tfstate.d/gcp-${count.index}-${var.gcp_k8s_regions[count.index]}/terraform.tfstate"
  }
}

data "terraform_remote_state" "tsb_mp" {
  backend = "local"
  config = {
    path = "../../tsb/mp/terraform.tfstate"
  }
}

module "argocd" {
  source                     = "../../modules/addons/argocd"
  cluster_name               = local.infra[var.cloud][var.cluster_id]["outputs"].cluster_name
  k8s_host                   = local.infra[var.cloud][var.cluster_id]["outputs"].host
  k8s_cluster_ca_certificate = local.infra[var.cloud][var.cluster_id]["outputs"].cluster_ca_certificate
  k8s_client_token           = local.infra[var.cloud][var.cluster_id]["outputs"].token
  password                   = var.tsb_password
}
