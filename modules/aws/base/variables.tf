variable "name_prefix" {
  description = "name prefix"
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

variable "output_path" {
}

variable "tags" {
  type = map
}
