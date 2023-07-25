data "aws_eks_cluster_auth" "cluster" {
  name       = var.cluster_name
}