variable "name_prefix" {
  description = "name prefix"
}

variable "owner" {
  description = "owner of this environment"
}

variable "location" {
  description = "location"
}

variable "resource_group_name" {
  description = "resource group name"
}


variable "cidr" {
  description = "cidr"
}

variable "vnet_subnet" {
  description = "vnet subnet id"
}

variable "registry" {
}

variable "registry_username" {
}

variable "registry_password" {
}

variable "jumpbox_username" {
}

variable "tsb_image_sync_username" {
}

variable "tsb_image_sync_apikey" {
}

variable "tsb_version" {
}

variable "output_path" {
}

variable "tetrate_internal_cr" {
  default = ""
}
variable "tetrate_internal_cr_token" {
  default = ""
}