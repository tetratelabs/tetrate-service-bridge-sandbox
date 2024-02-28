variable "name_prefix" {
  type        = string
  description = "name prefix"
}

variable "location" {
  type        = string
  description = "location"
}

variable "resource_group_name" {
  type        = string
  description = "resource group name"
}

variable "cidr" {
  type        = string
  description = "cidr"
}

variable "vnet_subnet" {
  type        = string
  description = "vnet subnet id"
}

variable "registry" {
  type = string
}

variable "registry_username" {
  type = string
}

variable "registry_password" {
  type = string
}

variable "tsb_helm_username" {
  type    = string
  default = ""
}

variable "tsb_helm_password" {
  type    = string
  default = ""
}

variable "jumpbox_username" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "tsb_image_sync_username" {
  type = string
}

variable "tsb_image_sync_apikey" {
  type = string
}

variable "tsb_version" {
  type = string
}

variable "tsb_helm_repository" {
  type    = string
  default = ""
}

variable "output_path" {
  type = string
}

variable "tags" {
  type = map(any)
}