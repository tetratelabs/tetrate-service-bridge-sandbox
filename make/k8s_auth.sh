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
CLOUD_PROVIDER=${2}

# Validate input values.
SUPPORTED_ACTIONS=("refresh_token_k8s")
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
  echo "  help                               Display this help message."
  echo "  refresh_token_k8s <cloud_provider> Refresh Kubernetes access token for the specified cloud provider."
}


# This function refreshes the Kubernetes access token for the specified cloud provider.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#
# Usage: refresh_token_k8s "gcp"
function refresh_token_k8s() {
  [[ -z "${1}" ]] && print_error "Please provide cloud provider as 1st argument" && return 1 || local cloud_provider="${1}" ;

  # Refresh token logic here.
  print_info "Going to refresh k8s token on cloud '${cloud_provider}'"
}

#
# Main execution.
#
case "${ACTION}" in
  help)
    help
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
