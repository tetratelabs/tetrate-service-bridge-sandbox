#!/usr/bin/env bash
#
# Helper script to refresh kubernetes tokens.
#
BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export BASE_DIR

source "${BASE_DIR}/helpers.sh"

ACTION=${1}
SUPPORTED_CLOUDS=("azure" "aws" "gcp")

# Validate input values.
SUPPORTED_ACTIONS=("help" "k8s_auth_aws" "k8s_auth_azure" "k8s_auth_gcp")
if ! [[ " ${SUPPORTED_ACTIONS[*]} " == *" ${ACTION} "* ]]; then
  print_error "Invalid action '${ACTION}'. Must be one of '${SUPPORTED_ACTIONS[*]}'."
  exit 1
fi

# This function provides help information for the script.
#
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
function refresh_token_k8s() {
  if [[ -z "${1}" ]] ; then print_error "Please provide cloud provider as 1st argument" ; return 1 ; else local cloud="${1}" ; fi
  if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${cloud} "* ]]; then print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'." ; return 1 ; fi

  print_info "Going to refresh k8s token on cloud '${cloud}'"
  set -e

  # Get the number of clusters for the specified cloud provider.
  local cluster_count=$(get_cluster_count "${TFVARS_JSON}" "${cloud}")

  for ((index = 0; index < cluster_count; index++)); do
    local cluster=$(get_cluster_config "${TFVARS_JSON}" "${cloud}" "${index}")
    local workspace=$(get_cluster_workspace "${cluster}")
    echo "Processing cluster:" 
    echo "${cluster}" | jq '.'

    run "pushd infra/${cloud}/k8s_auth > /dev/null"
    run "terraform workspace new ${workspace} || true"
    run "terraform workspace select ${workspace}"
    run "terraform init"
    run "terraform apply ${TERRAFORM_APPLY_ARGS} -refresh=false -var-file=../../../${TFVARS_JSON} -var=cluster='${cluster}'"
    run "terraform workspace select default"
    run "popd > /dev/null"
  done
}

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