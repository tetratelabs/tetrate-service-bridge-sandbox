variable "name_prefix" {
  description = "name prefix"
}
variable "region" {
}

variable "vpc_id" {
}

variable "vpc_subnet" {
}

variable "cidr" {

}

variable "registry" {
}
variable "registry_name" {
}

variable "jumpbox_username" {
}

variable "tsb_image_sync_username" {
}

variable "tsb_image_sync_apikey" {
}

variable "tsb_version" {
}

variable "tsb_helm_repository" {
  default = ""
}
variable "output_path" {
}

variable "tags" {
  type = map
}
