variable "name_prefix" {
  description = "name prefix"
}

variable "owner" {
  description = "owner of this environment"
}

variable "cidr" {
  description = "cidr"
}

variable "min_az_count" {
  default = 2
}

variable "max_az_count" {
  default = 3
}
