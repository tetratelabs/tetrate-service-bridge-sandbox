variable "cloud" {
}

variable "k8s_regions" {
  type = list
}

variable "cluster_id" {
}

variable "eshop_host" {
  default = "eshop.tetrate.io"
}

variable "payments_host" {
  default = "payments.tetrate.io"
}

variable "payments_latency_ms" {
  default = 200
}

variable "checkout_error_percentage" {
  default = 20
}

variable "tenant_owner" {
  default = "nacx"
}

variable "eshop_owner" {
  default = "zack"
}

variable "payments_owner" {
  default = "wusheng"
}
