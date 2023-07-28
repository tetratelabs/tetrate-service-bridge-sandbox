variable "name_prefix" {
  type        = string
  description = "name prefix"
}

variable "region" {
  type        = string
  description = "region"
}

variable "project_id" {
  type = string
}

variable "cidr" {
  type        = string
  description = "cidr"
}

variable "min_az_count" {
  type    = number
  default = 2
}

variable "max_az_count" {
  type    = number
  default = 3
}
