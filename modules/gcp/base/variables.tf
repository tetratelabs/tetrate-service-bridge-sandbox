variable "name_prefix" {
  description = "name prefix"
}

variable "region" {
  description = "region"
}

variable "project_id" {
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

variable "org_id" {
  default = "775566979306"
}

variable "billing_id" {
  default = "0183E5-447B34-776DEB"
}
