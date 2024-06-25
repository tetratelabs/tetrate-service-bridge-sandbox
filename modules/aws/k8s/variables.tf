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

variable "instance_type" {
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

variable "lb_controller_helm_chart_version" {
  default = "1.7.1"
}

variable "lb_controller_settings" {
  default = { "controllerConfig" = { "featureGates" = { "SubnetsClusterTagCheck" : "false" } } }
}
