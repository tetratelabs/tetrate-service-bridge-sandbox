provider "aws" {
  default_tags {
    tags = local.aws_tags
  }
  region = var.aws_k8s_regions[0]
}
