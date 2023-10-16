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
CLOUD_PROVIDER=${2}

# Validate input values.
SUPPORTED_ACTIONS=("deploy_mp" "deploy_cp_dp")
if ! [[ " ${SUPPORTED_ACTIONS[*]} " == *" ${ACTION} "* ]]; then
  print_error "Invalid action. Must be one of '${SUPPORTED_ACTIONS[*]}'."
  exit 1
fi
SUPPORTED_CLOUDS=("azure" "aws" "gcp")
if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${CLOUD_PROVIDER} "* ]]; then
  print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'."
  exit 1
fi

# This function provides help information for the script.
function help() {
  echo "Usage: $0 <command> [options]"
  echo "Commands:"
  echo "  help                           Display this help message."
  echo "  deploy_mp     <cloud_provider> Deploy tsb management plane on the specified cloud provider."
  echo "  deploy_cp_dp  <cloud_provider> Deploy tsb control and data plane on the specified cloud provider."
}


# This function deploys tsb management plane on the specified cloud provider.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#
# Usage: deploy_mp "azure"
function deploy_mp() {
  [[ -z "${1}" ]] && print_error "Please provide cloud provider as 1st argument" && return 1 || local cloud_provider="${1}" ;

  # Deployment logic here
  print_info "Going to deploy tsb management plane on cloud '${cloud_provider}'"
}

# This function deploys tsb control and data plane on the specified cloud provider.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#
# Usage: destroy_k8s "gcp"
function deploy_cp_dp() {
  [[ -z "${1}" ]] && print_error "Please provide cloud provider as 1st argument" && return 1 || local cloud_provider="${1}" ;

  # Deployment logic here
  print_info "Going to deploy tsb control and data plane on cloud '${cloud_provider}'"
}


#
# Main execution
#
case "${ACTION}" in
  help)
    help
    ;;
  deploy_mp)
    print_stage "Going to deploy tsb management plane on cloud '${CLOUD_PROVIDER}'"
    deploy_mp "${CLOUD_PROVIDER}" 
    ;;
  deploy_cp_dp)
    print_stage "Going to deploy tsb control and data plane on cloud '${CLOUD_PROVIDER}'"
    deploy_cp_dp "${CLOUD_PROVIDER}" 
    ;;
  *)
    print_error "Invalid option. Use 'help' to see available commands."
    help
    ;;
esac
