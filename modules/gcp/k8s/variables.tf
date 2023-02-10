variable "name_prefix" {
  description = "name prefix"
}
variable "cluster_name" {
  description = "cluster name"
}

variable "project_id" {
}

variable "vpc_id" {
}

variable "vpc_subnet" {
}

variable "region" {
}

variable "preemptible_nodes" {
  default = false
}

variable "k8s_version" {
}

variable "output_path" {
}

variable "tags" {
  type = map
}