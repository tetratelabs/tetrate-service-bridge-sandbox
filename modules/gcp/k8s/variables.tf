variable "name_prefix" {
  type        = string
  description = "name prefix"
}
variable "cluster_name" {
  type        = string
  description = "cluster name"
}

variable "project_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_subnet" {
  type = string
}

variable "region" {
  type = string
}

variable "preemptible_nodes" {
  type    = bool
  default = false
}

variable "k8s_version" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "output_path" {
  type = string
}

variable "tags" {
  type = map(any)
}