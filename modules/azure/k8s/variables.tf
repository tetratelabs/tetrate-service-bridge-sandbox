variable "name_prefix" {
  type        = string
  description = "name prefix"
}

variable "location" {
  type        = string
  description = "location"
}

variable "cluster_name" {
  type        = string
  description = "cluster name"
}

variable "resource_group_name" {
  type        = string
  description = "resource group name"
}

variable "vnet_subnet" {
  type        = string
  description = "vnet subnet id"
}

variable "registry_id" {
  type = string
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