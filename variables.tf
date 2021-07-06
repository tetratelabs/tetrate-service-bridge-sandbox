variable "name_prefix" {
  description = "name prefix"
}

variable "location" {
  description = "location"
}

variable "cidr" {
  description = "cidr"
}

variable "image-sync_username" {
}

variable "image-sync_apikey" {
}

variable "tctl_username" {
  default = "admin"
}

variable "tctl_password" {
  default = "admin"
}

variable "tsb_version" {
  default = "1.3.0"
}

variable "jumpbox_username" {
  default = "tsbadmin"
}

variable "cp_count" {
  default = 1
}
