variable "name_prefix" {
  type        = string
  description = "name prefix"
}

variable "cidr" {
  type        = string
  description = "cidr"
}

variable "min_az_count" {
  type    = string
  default = 1
}

variable "max_az_count" {
  type    = string
  default = 3
}

variable "output_path" {
  type = string
}

variable "tags" {
  type = map(any)
}
