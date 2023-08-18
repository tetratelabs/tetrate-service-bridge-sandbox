variable "name_prefix" {
  type        = string
  description = "name prefix"
}

variable "cluster_name" {
  type        = string
  description = "cluster name"
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_subnets" {
  description = "vnet subnet ids"
}

variable "k8s_version" {
  type = string
}

variable "jumpbox_iam_role_arn" {
  type = string
}

variable "output_path" {
  type = string
}

variable "tags" {
  type = map(any)
}