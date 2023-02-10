variable "name_prefix" {
  description = "name prefix"
}

variable "cluster_name" {
  description = "cluster name"
}

variable "region" {
}

variable "vpc_id" {
}

variable "vpc_subnets" {
  description = "vnet subnet ids"
}

variable "k8s_version" {
}

variable "output_path" {
}

variable "tags" {
  type = map
}