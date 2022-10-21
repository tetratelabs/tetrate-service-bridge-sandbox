variable "dns_zone" {
    default = null
}
variable "fqdn" {
}
variable "address" {
}

locals {
  # We can get the project ID by parsing it from the `registry` output variable for the MP install
  mp_state = jsondecode(file("../../mp/terraform.tfstate"))
  project_id = trimprefix(local.mp_state.outputs.registry.value, "gcr.io/")
  vpc_id = reverse(split("/", local.mp_state.outputs.vpc_id.value))[0]
}
