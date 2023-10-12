#!/usr/bin/env bash
#
# Helper script for addons: deploy and destroy of argocd, fluxcd, tsb-monitoring and external-dns.

export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${BASE_DIR}/helpers.sh

ACTION=${1}
CLOUD_PROVIDER=${2}
ADDON_NAME=${3}

# This function provides help information for the script.
function help() {
  echo "Usage: $0 <command> [options]"
  echo "Commands:"
  echo "  help                                        Display this help message."
  echo "  deploy_addon  <cloud_provider> <addon_name> Deploy addon on the specified cloud provider."
  echo "  destroy_addon <cloud_provider> <addon_name> Destroy addon on the specified cloud provider."
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
if [[ "${ACTION}" == "deploy_addon" || "${ACTION}" == "destroy_addon" ]]; then
  if [[ "${CLOUD_PROVIDER}" != "azure" && "${CLOUD_PROVIDER}" != "aws" && "${CLOUD_PROVIDER}" != "gcp" ]]; then
    print_error "Invalid cloud provider. Must be one of 'azure', 'aws', or 'gcp'."
    exit 1
  fi
  if [[ "${ADDON_NAME}" != "argocd" && "${ADDON_NAME}" != "fluxcd" && "${ADDON_NAME}" != "tsb-monitoring" && "${ADDON_NAME}" != "external-dns" ]]; then
    print_error "Invalid addon. Must be one of 'argocd', 'fluxcd', 'tsb-monitoring' or 'external-dns'."
    exit 1
  fi
fi



# This function deploys the specified addon on the specified cloud provider.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#   $2 - The addon name ("argocd", "fluxcd", "tsb-monitoring", or 'external-dns').
#
# Usage: deploy_addon "azure" "argocd"
function deploy_addon() {
  local cloud_provider=${1}
  local addon_name=${2}
  # Deployment logic here
}

# This function destroy the specified addon on the specified cloud provider.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#   $2 - The addon name ("argocd", "fluxcd", "tsb-monitoring", or 'external-dns').
#
# Usage: destroy_addon "azure" "argocd"
function destroy_addon() {
  local cloud_provider=${1}
  local addon=${2}
  # Destroy logic here
}


#
# Main execution.
#
case "${ACTION}" in
  help)
    help
    ;;
  deploy_addon)
    print_stage "Going to deploy addon ${ADDON_NAME} on cloud ${CLOUD_PROVIDER}" 
    deploy_addon "${CLOUD_PROVIDER}" "${ADDON_NAME}"
    ;;
  destroy_addon)
    print_stage "Going to destroy addon ${ADDON_NAME} on cloud ${CLOUD_PROVIDER}"
    destroy_addon "${CLOUD_PROVIDER}" "${ADDON_NAME}"
    ;;
  *)
    print_error "Invalid option. Use 'help' to see available commands."
    help
    ;;
esac
