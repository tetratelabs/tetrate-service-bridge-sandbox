#!/usr/bin/env bash
#
# Helper script to deploy tsb management, control and data planes.

BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export BASE_DIR

# shellcheck source=/dev/null
source "${BASE_DIR}/helpers.sh"
# shellcheck source=/dev/null
source "${BASE_DIR}/variables.sh"

ACTION=${1}
SUPPORTED_CLOUDS=("azure" "aws" "gcp")

# Validate input values.
SUPPORTED_ACTIONS=("help" "tsb_mp" "tsb_cp_aws" "tsb_cp_azure" "tsb_cp_gcp" "destroy_remote")
if ! [[ " ${SUPPORTED_ACTIONS[*]} " == *" ${ACTION} "* ]]; then
  print_error "Invalid action '${ACTION}'. Must be one of '${SUPPORTED_ACTIONS[*]}'."
  exit 1
fi

# This function provides help information for the script.
function help() {
  echo "Usage: $0 <command> [options]"
  echo "Commands:"
  echo "  help            Display this help message."
  echo "  tsb_mp          Deploy tsb management plane on the configured cloud provider."
  echo "  tsb_cp_aws      Deploy tsb control and data plane on the specified cloud provider."
  echo "  tsb_cp_azure    Deploy tsb control and data plane on the specified cloud provider."
  echo "  tsb_cp_gcp      Deploy tsb control and data plane on the specified cloud provider."
  echo "  destroy_remote  Destroy tsb management plane fqdn on the configured dns cloud provider."
}

# This function deploys tsb management plane on configured cloud provider.
#
# Usage: deploy_mp
function deploy_mp() {
  print_info "Going to deploy tsb management plane"
  set -e

  local cluster=$(get_mp_cluster_config "${TFVARS_JSON}")
  local cloud=$(get_cluster_cloud "${cluster}")
  local workspace=${NAME_PREFIX}
  source "${BASE_DIR}/k8s_auth.sh" k8s_auth_${cloud}
  echo processing cluster: "${cluster}"

  run "pushd tsb/mp > /dev/null"
  run "terraform workspace new ${workspace} || true"
  run "terraform workspace select ${workspace}"
  run "terraform init"
  run "terraform apply ${TERRAFORM_APPLY_ARGS} -target=module.cert-manager -target=module.es -target=data.terraform_remote_state.infra -var-file=../../${TFVARS_JSON} -var=cluster='${cluster}'"
  run "terraform apply ${TERRAFORM_APPLY_ARGS} -target=module.tsb_mp.kubectl_manifest.manifests_certs -target=data.terraform_remote_state.infra -var-file=../../${TFVARS_JSON} -var=cluster='${cluster}'"
  run "terraform apply ${TERRAFORM_APPLY_ARGS} -var-file=../../${TFVARS_JSON} -var=cluster='${cluster}'"
  run "terraform output ${TERRAFORM_OUTPUT_ARGS} | jq . > ../../outputs/terraform_outputs/terraform-tsb-mp.json"
  run "terraform workspace select default"
  run "popd > /dev/null"

  print_info "Finished deploying tsb management plane on cloud '${cloud}'"
}

# This function deploys tsb management plane fqdn on configured cloud provider.
#
# Usage: deploy_mp_fqdn
function deploy_mp_fqdn() {
  print_info "Going to deploy tsb management plane fqdn"
  set -e

  local cluster=$(get_mp_cluster_config "${TFVARS_JSON}")
  local fqdn=${TETRATE_FQDN}
  local dns_provider=${DNS_PROVIDER}
  local address=$(jq -r "if .ingress_ip.value != \"\" then .ingress_ip.value else .ingress_hostname.value end" outputs/terraform_outputs/terraform-tsb-mp.json)
  local workspace=${NAME_PREFIX}

  print_info "Going to deploy tsb management plane fqdn '${fqdn}' with address '${address}' on cloud '${dns_provider}'"
  echo processing cluster: "${cluster}"

  run "pushd tsb/fqdn/${dns_provider} > /dev/null"
  run "terraform workspace new ${workspace} || true"
  run "terraform workspace select ${workspace}"
  run "terraform init"
  run "terraform apply ${TERRAFORM_APPLY_ARGS} -var-file=../../../${TFVARS_JSON} -var=cluster='${cluster}' -var=address=${address} -var=fqdn=${fqdn}"
  run "terraform workspace select default"
  run "popd > /dev/null"

  print_info "Finished deploying tsb management plane fqdn on cloud '${dns_provider}'"
}

# This function destroys tsb management plane fqdn on configured cloud provider.
#
# Usage: destroy_mp_fqdn
function destroy_mp_fqdn() {
  print_info "Going to destroy tsb management plane fqdn"
  set -e

  local cluster=$(get_mp_cluster_config "${TFVARS_JSON}")
  local fqdn=${TETRATE_FQDN}
  local dns_provider=${DNS_PROVIDER}
  local address=$(jq -r "if .ingress_ip.value != \"\" then .ingress_ip.value else .ingress_hostname.value end" outputs/terraform_outputs/terraform-tsb-mp.json)
  local workspace=${NAME_PREFIX}

  print_info "Going to destroy tsb management plane fqdn '${fqdn}' with address '${address}' on cloud '${dns_provider}'"
  echo processing cluster: "${cluster}"

  run "pushd tsb/fqdn/${dns_provider} > /dev/null"
  run "terraform workspace select ${workspace}"
  run "terraform destroy ${TERRAFORM_DESTROY_ARGS} -var-file=../../../${TFVARS_JSON} -var=cluster='${cluster}' -var=address=${address} -var=fqdn=${fqdn}"
  run "terraform workspace select default"
  run "popd > /dev/null"

  print_info "Finished destroying tsb management plane fqdn on cloud '${dns_provider}'"
}

# This function deploys tsb control and data plane on the specified cloud provider.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#

function deploy_cp() {
  if [[ -z "${1}" ]] ; then print_error "Please provide cloud provider as 1st argument" ; return 1 ; else local cloud="${1}" ; fi
  if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${cloud} "* ]]; then print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'." ; return 1 ; fi

  print_info "Going to deploy tsb control and data plane on cloud '${cloud}'"
  source "${BASE_DIR}/k8s_auth.sh" k8s_auth_${cloud}
  set -e

  # Get the number of clusters for the specified cloud provider.
  local cluster_count=$(get_cluster_count "${TFVARS_JSON}" "${cloud}")

  for ((index = 0; index < cluster_count; index++)); do
    local cluster=$(get_cluster_config "${TFVARS_JSON}" "${cloud}" "${index}")
    local workspace=$(get_cluster_workspace "${cluster}")
    if [[ $(is_cluster_cp "${cluster}") == false ]] ; then echo "Skipping mp only" ; continue ; fi
    echo processing cluster: "${cluster}"

    run "pushd tsb/cp > /dev/null"
    run "terraform workspace new ${workspace} || true"
    run "terraform workspace select ${workspace}"
    run "terraform init"
    run "terraform apply ${TERRAFORM_APPLY_ARGS} -var-file=../../${TFVARS_JSON} -var=cluster='${cluster}'"
    run "terraform workspace select default"
    run "popd > /dev/null"
  done

  print_info "Finished deploying tsb control and data plane on cloud '${cloud}'"
}


#
# Main execution
#
case "${ACTION}" in
  help)
    help
    ;;
  tsb_mp)
    print_stage "Going to deploy tsb management plane"
    deploy_mp
    deploy_mp_fqdn
    ;;
  tsb_cp_aws)
    print_stage "Going to deploy tsb control and data plane on cloud 'aws'"
    deploy_cp "aws"
    ;;
  tsb_cp_azure)
    print_stage "Going to deploy tsb control and data plane on cloud 'azure'"
    deploy_cp "azure"
    ;;
  tsb_cp_gcp)
    print_stage "Going to deploy tsb control and data plane on cloud 'gcp'"
    deploy_cp "gcp"
    ;;
  destroy_remote)
    print_stage "Going to destroy tsb management plane fqdn"
    destroy_mp_fqdn
    ;;
  *)
    print_error "Invalid option. Use 'help' to see available commands."
    help
    ;;
esac