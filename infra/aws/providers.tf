terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "aws" {
  region = local.cluster.region

  # Re-enable this once https://github.com/hashicorp/terraform-provider-aws/issues/19583
  # is fixed. Until then, the workaround is to manually merge
  # the tags in every resource.
  # default_tags {
  #   tags = local.tags
  # }
}