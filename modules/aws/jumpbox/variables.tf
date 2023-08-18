variable "name_prefix" {
  type        = string
  description = "name prefix"
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_subnet" {
  type = string
}

variable "cidr" {
  type = string
}

variable "registry" {
  type = string
}

variable "registry_name" {
  type = string
}

variable "jumpbox_username" {
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
  type = string
}

variable "output_path" {
  type = string
}

variable "tags" {
  type = map(any)
}
