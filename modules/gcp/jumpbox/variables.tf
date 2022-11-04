variable "name_prefix" {
  description = "name prefix"
}

variable "owner" {
  description = "owner of this environment"
}

variable "region" {
}

variable "project_id" {
}

variable "vpc_id" {
}

variable "vpc_subnet" {
}

variable "registry" {
}

variable "tsb_image_sync_username" {
}

variable "tsb_image_sync_apikey" {
}

variable "tsb_version" {
}

variable "jumpbox_username" {
}

variable "machine_type" {
}

variable "output_path" {
}

variable "tetrate_internal_cr" {
  default = ""
}
variable "tetrate_internal_cr_token" {
  default = ""
}