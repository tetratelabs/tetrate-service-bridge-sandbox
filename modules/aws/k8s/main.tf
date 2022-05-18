module "eks" {
  source          = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v17.18.0"
  cluster_name    = var.cluster_name
  vpc_id          = var.vpc_id
  subnets         = var.vpc_subnets
  cluster_version = "1.21"



  worker_groups = [
    {
      name                 = "worker-group-2"
      instance_type        = "t2.medium"
      asg_desired_capacity = 3
    },
  ]

  manage_aws_auth = true
}

data "aws_eks_cluster" "cluster" {
  name       = var.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = var.cluster_name
  depends_on = [module.eks]
}


