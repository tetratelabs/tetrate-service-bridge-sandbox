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
variable "tags" {
  type = map 
}