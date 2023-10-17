#!/usr/bin/env bash
#
# Helper script to refresh kubernetes tokens.

BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export BASE_DIR

# shellcheck source=/dev/null
source "${BASE_DIR}/helpers.sh"
# shellcheck source=/dev/null
source "${BASE_DIR}/variables.sh"

ACTION=${1}
SUPPORTED_CLOUDS=("azure" "aws" "gcp")

# Validate input values.
SUPPORTED_ACTIONS=("help" "k8s_auth_aws" "k8s_auth_azure" "k8s_auth_gcp")
if ! [[ " ${SUPPORTED_ACTIONS[*]} " == *" ${ACTION} "* ]]; then
  print_error "Invalid action '${ACTION}'. Must be one of '${SUPPORTED_ACTIONS[*]}'."
  exit 1
fi

# This function provides help information for the script.
function help() {
  echo "Usage: $0 <command> [options]"
  echo "Commands:"
  echo "  help              Display this help message."
  echo "  k8s_auth_aws      Refresh Kubernetes access token on aws eks clusters."
  echo "  k8s_auth_azure    Refresh Kubernetes access token on azure aks clusters."
  echo "  k8s_auth_gcp      Refresh Kubernetes access token on gcp gke clusters."
}

# This function refreshes the Kubernetes access token for the specified cloud provider.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#
# Usage: refresh_token_k8s "gcp"
function refresh_token_k8s() {
  if [[ -z "${1}" ]] ; then print_error "Please provide cloud provider as 1st argument" ; return 1 ; else local cloud_provider="${1}" ; fi
  if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${cloud_provider} "* ]]; then print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'." ; return 1 ; fi

  print_info "Going to refresh k8s token on cloud '${cloud_provider}'"
  set -e

  local index=0
  local name_prefix=$(jq -r '.name_prefix' "${TFVARS_JSON}")

  while read -r region; do
    cluster_name="${cloud_provider}-${name_prefix}-${region}-${index}"
    echo cloud="${cloud_provider} region=${region} cluster_id=${index} cluster_name=${cluster_name}"
    
    run "pushd infra/${cloud_provider}/k8s_auth > /dev/null"
    run "terraform workspace new ${cloud_provider}-${index}-${region} || true"
    run "terraform workspace select ${cloud_provider}-${index}-${region}"
    run "terraform init"
    run "terraform apply ${TERRAFORM_APPLY_ARGS} -refresh=false -var-file=../../../${TFVARS_JSON} -var=${cloud_provider}_k8s_region=${region} -var=cluster_id=${index}"
    run "terraform workspace select default"
    run "popd > /dev/null"

    index=$((index+1))
  done < <(jq -r ".${cloud_provider}_k8s_regions[]" "${TFVARS_JSON}")
}

#
# Main execution.
#
case "${ACTION}" in
  help)
    help
    ;;
  k8s_auth_aws)
    print_stage "Going to refresh k8s token for cloud 'aws'"
    refresh_token_k8s "aws"
    ;;
  k8s_auth_azure)
    print_stage "Going to refresh k8s token for cloud 'azure'"
    refresh_token_k8s "azure"
    ;;
  k8s_auth_gcp)
    print_stage "Going to refresh k8s token for cloud 'gcp'"
    refresh_token_k8s "gcp"
    ;;
  *)
    print_error "Invalid option. Use 'help' to see available commands."
    help
    ;;
esac
