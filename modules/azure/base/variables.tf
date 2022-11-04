variable "name_prefix" {
  description = "name prefix"
}

variable "owner" {
  description = "owner of this environment"
}

variable "location" {
  description = "location"
}

variable "cidr" {
  description = "cidr"
}

variable "subnets_count" {
  default = "3"
}
