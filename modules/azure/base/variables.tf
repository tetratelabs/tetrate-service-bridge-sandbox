variable "name_prefix" {
  type        = string
  description = "name prefix"
}

variable "location" {
  type        = string
  description = "location"
}

variable "cidr" {
  type        = string
  description = "cidr"
}

variable "subnets_count" {
  type    = string
  default = "3"
}

variable "tags" {
  type = map(any)
}