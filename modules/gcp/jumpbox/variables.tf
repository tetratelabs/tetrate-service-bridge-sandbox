variable "name_prefix" {
  type        = string
  description = "name prefix"
}

variable "region" {
  type = string
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

variable "registry" {
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

variable "output_path" {
  type = string
}

variable "tags" {
  type = map(any)
}