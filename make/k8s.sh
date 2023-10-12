#!/usr/bin/env bash
#
# Helper script for kubernetes: deploy, destroy clusters and refresh tokens.

export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${BASE_DIR}/helpers.sh

ACTION=${1}
CLOUD_PROVIDER=${2}

# This function provides help information for the script.
function help() {
  echo "Usage: $0 <command> [options]"
  echo "Commands:"
  echo "  help                               Display this help message."
  echo "  deploy_k8s        <cloud_provider> Deploy Kubernetes on the specified cloud provider."
  echo "  destroy_k8s       <cloud_provider> Destroy Kubernetes on the specified cloud provider."
  echo "  refresh_token_k8s <cloud_provider> Refresh Kubernetes access token for the specified cloud provider."
}

# Check if the input parameters are correctly given.
if [[ -z "${ACTION}" ]]; then
  print_error "No command provided."
  help
  exit 1
fi

# Check if TFVARS_JSON is not defined and exit.
if [ -z "${TFVARS_JSON}" ]; then
  print_error "TFVARS_JSON is not defined."
  exit 1
fi

# Check if the file pointed to by TFVARS_JSON does not exist and exit.
if [ ! -f "${TFVARS_JSON}" ]; then
  print_error "File '${TFVARS_JSON}' does not exist."
  exit 1
fi

# Validate input values.
if [[ "${ACTION}" == "deploy_k8s" || "${ACTION}" == "destroy_k8s" || "${ACTION}" == "refresh_token_k8s" ]]; then
  if [[ "${CLOUD_PROVIDER}" != "azure" && "${CLOUD_PROVIDER}" != "aws" && "${CLOUD_PROVIDER}" != "gcp" ]]; then
    print_error "Invalid cloud provider. Must be one of 'azure', 'aws', or 'gcp'."
    exit 1
  fi
fi

# This function deploys Kubernetes on the specified cloud provider.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#
# Usage: deploy_k8s "azure"
function deploy_k8s() {
  local cloud_provider=${1}
  # Deployment logic here
}

# This function destroys Kubernetes on the specified cloud provider.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#
# Usage: destroy_k8s "gcp"
function destroy_k8s() {
  local cloud_provider=${1}
  # Destruction logic here
}

# This function refreshes the Kubernetes access token for the specified cloud provider.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#
# Usage: refresh_token_k8s "gcp"
function refresh_token_k8s() {
  local cloud_provider=${1}
  # Refresh token logic here.
}

#
# Main execution.
#
case "${ACTION}" in
  help)
    help
    ;;
  deploy_k8s)
    print_stage "Going to deploy k8s on cloud ${CLOUD_PROVIDER}"
    deploy_k8s "${CLOUD_PROVIDER}" 
    ;;
  destroy_k8s)
    print_stage "Going to destroy k8s on cloud ${CLOUD_PROVIDER}"
    destroy_k8s "${CLOUD_PROVIDER}" 
    ;;
  refresh_token_k8s)
    print_stage "Going to refresh k8s token for cloud ${CLOUD_PROVIDER}"
    refresh_token_k8s "${CLOUD_PROVIDER}"
    ;;
  *)
    print_error "Invalid option. Use 'help' to see available commands."
    help
    ;;
esac
