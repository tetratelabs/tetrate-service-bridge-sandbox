#!/usr/bin/env bash
#
# Helper script to deploy tsb management, control and data planes.

export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${BASE_DIR}/helpers.sh

ACTION=${1}
CLOUD_PROVIDER=${2}

# This function provides help information for the script.
function help() {
  echo "Usage: $0 <command> [options]"
  echo "Commands:"
  echo "  help                           Display this help message."
  echo "  deploy_mp     <cloud_provider> Deploy tsb management plane on the specified cloud provider."
  echo "  deploy_cp_dp  <cloud_provider> Deploy tsb control and data plane on the specified cloud provider."
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
if [[ "${ACTION}" == "deploy_mp" || "${ACTION}" == "deploy_cp_dp" ]]; then
  if [[ "${CLOUD_PROVIDER}" != "azure" && "${CLOUD_PROVIDER}" != "aws" && "${CLOUD_PROVIDER}" != "gcp" ]]; then
    print_error "Invalid cloud provider. Must be one of 'azure', 'aws', or 'gcp'."
    exit 1
  fi
fi

# This function deploys tsb management plane on the specified cloud provider.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#
# Usage: deploy_mp "azure"
function deploy_mp() {
  local cloud_provider=${1}
  # Deployment logic here
}

# This function deploys tsb control and data plane on the specified cloud provider.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#
# Usage: destroy_k8s "gcp"
function deploy_cp_dp() {
  local cloud_provider=${1}
  # Deployment logic here
}


#
# Main execution
#
case "${ACTION}" in
  help)
    help
    ;;
  deploy_mp)
    print_stage "Going to deploy tsb management plane on cloud ${CLOUD_PROVIDER}"
    deploy_mp "${CLOUD_PROVIDER}" 
    ;;
  deploy_cp_dp)
    print_stage "Going to deploy tsb control and data plane on cloud ${CLOUD_PROVIDER}"
    deploy_cp_dp "${CLOUD_PROVIDER}" 
    ;;
  *)
    print_error "Invalid option. Use 'help' to see available commands."
    help
    ;;
esac
