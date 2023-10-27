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
  set -e

  local cloud_provider=$(jq -r '.tsb_mp.cloud' "${TFVARS_JSON}")
  print_info "Going to deploy tsb management plane on cloud '${cloud_provider}'"
  source ${BASE_DIR}/k8s_auth.sh k8s_auth_${cloud_provider}

  run "pushd tsb/mp > /dev/null"
  run "terraform workspace select default"
  run "terraform init"
  run "terraform apply ${TERRAFORM_APPLY_ARGS} -target=module.cert-manager -target=module.es -target=data.terraform_remote_state.infra -var-file=../../${TFVARS_JSON}"
  run "terraform apply ${TERRAFORM_APPLY_ARGS} -target=module.tsb_mp.kubectl_manifest.manifests_certs -target=data.terraform_remote_state.infra -var-file=../../${TFVARS_JSON}"
  run "terraform apply ${TERRAFORM_APPLY_ARGS} -var-file=../../${TFVARS_JSON}"
  run "terraform output ${TERRAFORM_OUTPUT_ARGS} | jq . > ../../outputs/terraform_outputs/terraform-tsb-mp.json"
  run "terraform workspace select default"
  run "popd > /dev/null"

  print_info "Finished deploying tsb management plane on cloud '${cloud_provider}'"
}

# This function deploys tsb management plane fqdn on configured cloud provider.
#
# Usage: deploy_mp_fqdn
function deploy_mp_fqdn() {
  set -e

  local fqdn=$(jq -r '.tsb_fqdn' "${TFVARS_JSON}")
  local address=$(jq -r "if .ingress_ip.value != \"\" then .ingress_ip.value else .ingress_hostname.value end" outputs/terraform_outputs/terraform-tsb-mp.json)
  local dns_provider=$(jq -r '.dns_provider' "${TFVARS_JSON}")
  if [ "${dns_provider}" == "null" ]; then
    dns_provider=$(jq -r '.tsb_fqdn' "${TFVARS_JSON}" | cut -d"." -f2 | sed 's/sandbox/gcp/g')
  fi
  print_info "Going to deploy tsb management plane fqdn on cloud '${dns_provider}'"

  run "pushd tsb/fqdn/${dns_provider} > /dev/null"
  run "terraform workspace select default"
  run "terraform init"
  run "terraform apply ${TERRAFORM_APPLY_ARGS} -var-file=../../../${TFVARS_JSON} -var=address=${address} -var=fqdn=${fqdn}"
  run "terraform workspace select default"
  run "popd > /dev/null"

  print_info "Finished deploying tsb management plane fqdn on cloud '${dns_provider}'"
}

# This function destroys tsb management plane fqdn on configured cloud provider.
#
# Usage: destroy_mp_fqdn
function destroy_mp_fqdn() {
  set -e

  local fqdn=$(jq -r '.tsb_fqdn' "${TFVARS_JSON}")
  local address=$(jq -r "if .ingress_ip.value != \"\" then .ingress_ip.value else .ingress_hostname.value end" outputs/terraform_outputs/terraform-tsb-mp.json)
  local dns_provider=$(jq -r '.dns_provider' "${TFVARS_JSON}")
  if [ "${dns_provider}" == "null" ]; then
    dns_provider=$(jq -r '.tsb_fqdn' "${TFVARS_JSON}" | cut -d"." -f2 | sed 's/sandbox/gcp/g')
  fi
  print_info "Going to destroy tsb management plane fqdn on cloud '${dns_provider}'"

  run "pushd tsb/fqdn/${dns_provider} > /dev/null"
  run "terraform workspace select default"
  run "terraform init"
  run "terraform destroy ${TERRAFORM_DESTROY_ARGS} -var-file="../../../terraform.tfvars.json" -var=address=${address} -var=fqdn=${fqdn}"
  run "terraform workspace select default"
  run "popd > /dev/null"

  print_info "Finished destroying tsb management plane fqdn on cloud '${dns_provider}'"
}

# This function deploys tsb control and data plane on the specified cloud provider.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#
# Usage: destroy_k8s "gcp"
function deploy_cp_dp() {
  if [[ -z "${1}" ]] ; then print_error "Please provide cloud provider as 1st argument" ; return 1 ; else local cloud_provider="${1}" ; fi
  if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${cloud_provider} "* ]]; then print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'." ; return 1 ; fi

  print_info "Going to deploy tsb control and data plane on cloud '${cloud_provider}'"
  source ${BASE_DIR}/k8s_auth.sh k8s_auth_${cloud_provider}
  set -e

  local index=0
  local name_prefix=$(jq -r '.name_prefix' "${TFVARS_JSON}")

  while read -r region; do
    cluster_name="${cloud_provider}-${name_prefix}-${region}-${index}"
    echo cloud="${cloud_provider} region=${region} cluster_id=${index} cluster_name=${cluster_name}"

    run "pushd tsb/cp > /dev/null"
    run "terraform workspace new ${cloud_provider}-${index}-${region} || true"
    run "terraform workspace select ${cloud_provider}-${index}-${region}"
    run "terraform init"
    run "terraform apply ${TERRAFORM_APPLY_ARGS} -var-file=../../${TFVARS_JSON} -var=cloud=${cloud_provider} -var=cluster_id=${index}"
    run "terraform workspace select default"
    run "popd > /dev/null"

    index=$((index+1))
  done < <(jq -r ".${cloud_provider}_k8s_regions[]" "${TFVARS_JSON}")

  print_info "Finished deploying tsb control and data plane on cloud '${cloud_provider}'"
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
    deploy_cp_dp "aws"
    ;;
  tsb_cp_azure)
    print_stage "Going to deploy tsb control and data plane on cloud 'azure'"
    deploy_cp_dp "azure"
    ;;
  tsb_cp_gcp)
    print_stage "Going to deploy tsb control and data plane on cloud 'gcp'"
    deploy_cp_dp "gcp"
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