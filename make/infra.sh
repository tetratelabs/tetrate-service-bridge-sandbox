#!/usr/bin/env bash
#
# Helper script to deploy and destroy cloud infra (including k8s)

BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export BASE_DIR

# shellcheck source=/dev/null
source "${BASE_DIR}/helpers.sh"
# shellcheck source=/dev/null
source "${BASE_DIR}/variables.sh"

ACTION=${1}
SUPPORTED_CLOUDS=("azure" "aws" "gcp")

# Validate input values.
SUPPORTED_ACTIONS=("help"
                   "aws_k8s" "azure_k8s" "gcp_k8s"
                   "destroy_aws" "destroy_azure" "destroy_gcp")
if ! [[ " ${SUPPORTED_ACTIONS[*]} " == *" ${ACTION} "* ]]; then
  print_error "Invalid action '${ACTION}'. Must be one of '${SUPPORTED_ACTIONS[*]}'."
  exit 1
fi

# This function provides help information for the script.
function help() {
  echo "Usage: $0 <command> [options]"
  echo "Commands:"
  echo "  help            Display this help message."
  echo "  aws_k8s         Deploy infrastructure on aws."
  echo "  azure_k8s       Deploy infrastructure on azure."
  echo "  gcp_k8s         Deploy infrastructure on gcp."
  echo "  destroy_aws     Destroy infrastructure on aws."
  echo "  destroy_azure   Destroy infrastructure on azure."
  echo "  destroy_gcp     Destroy infrastructure on gcp."
}

# This function deploys infra on the specified cloud provider.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#
# Usage: deploy_infra "azure"
function deploy_infra() {
  if [[ -z "${1}" ]] ; then print_error "Please provide cloud provider as 1st argument" ; return 1 ; else local cloud_provider="${1}" ; fi
  if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${cloud_provider} "* ]]; then print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'." ; return 1 ; fi

  print_info "Going to deploy infra on cloud '${cloud_provider}'"
  set -e

  local index=0
  local name_prefix=$(jq -r '.name_prefix' "${TFVARS_JSON}")

  while read -r region; do
    cluster_name="${cloud_provider}-${name_prefix}-${region}-${index}"
    echo cloud="${cloud_provider} region=${region} cluster_id=${index} cluster_name=${cluster_name}"

    run "pushd infra/${cloud_provider} > /dev/null"
    run "terraform workspace new ${cloud_provider}-${index}-${region} || true"
    run "terraform workspace select ${cloud_provider}-${index}-${region}"
    run "terraform init"
    run "terraform apply ${TERRAFORM_APPLY_ARGS} -target module.${cloud_provider}_base -var-file=../../${TFVARS_JSON} -var=${cloud_provider}_k8s_region=${region} -var=cluster_name=${cluster_name} -var=cluster_id=${index}"
    run "terraform apply ${TERRAFORM_APPLY_ARGS} -var-file=../../${TFVARS_JSON} -var=${cloud_provider}_k8s_region=${region} -var=cluster_name=${cluster_name} -var=cluster_id=${index}"
    run "terraform output ${TERRAFORM_OUTPUT_ARGS} | jq . > ../../outputs/terraform_outputs/terraform-${cloud_provider}-${cluster_name}-${index}.json"
    run "terraform workspace select default"
    run "popd > /dev/null"

    index=$((index+1))
  done < <(jq -r ".${cloud_provider}_k8s_regions[]" "${TFVARS_JSON}")

  print_info "Finished deploying infra on cloud '${cloud_provider}'"
}

# This function destroys infra on the specified cloud provider.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#
# Usage: destroy_infra "gcp"
function destroy_infra() {
  if [[ -z "${1}" ]] ; then print_error "Please provide cloud provider as 1st argument" ; return 1 ; else local cloud_provider="${1}" ; fi
  if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${cloud_provider} "* ]]; then print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'." ; return 1 ; fi

  # Destruction logic here
  print_info "Going to destroy infra on cloud '${cloud_provider}'"
  set -e

  index=0
  name_prefix=$(jq -r '.name_prefix' "${TFVARS_JSON}")

  while read -r region; do
    cluster_name="${cloud_provider}-${name_prefix}-${region}-${index}"
    echo "cloud=${cloud_provider} region=${region} cluster_id=${index} cluster_name=${cluster_name}"

    run "cd infra/${cloud_provider}"
    run "terraform workspace select ${cloud_provider}-${index}-${region}"
    run "terraform destroy ${TERRAFORM_DESTROY_ARGS} -var-file=../../${TFVARS_JSON} -var=${cloud_provider}_k8s_region=${region} -var=cluster_id=${index} -var=cluster_name=${cluster_name}"
    run "terraform workspace select default"
    run "terraform workspace delete ${TERRAFORM_WORKSPACE_ARGS} ${cloud_provider}-${index}-${region}"
    run "cd ../.."

    index=$((index+1))
  done < <(jq -r ".${cloud_provider}_k8s_regions[]" "${TFVARS_JSON}")

  print_info "Finished destroying infra on cloud '${cloud_provider}'"
}

#
# Main execution.
#
case "${ACTION}" in
  help)
    help
    ;;
  aws_k8s)
    print_stage "Going to deploy infra on cloud 'aws'"
    deploy_infra "aws"
    ;;
  azure_k8s)
    print_stage "Going to deploy infra on cloud 'azure'"
    deploy_infra "azure"
    ;;
  gcp_k8s)
    print_stage "Going to deploy infra on cloud 'gcp'"
    deploy_infra "gcp"
    ;;
  destroy_aws)
    print_stage "Going to destroy infra on cloud 'aws'"
    destroy_infra "aws"
    ;;
  destroy_azure)
    print_stage "Going to destroy infra on cloud 'azure'"
    destroy_infra "azure"
    ;;
  destroy_gcp)
    print_stage "Going to destroy infra on cloud 'gcp'"
    destroy_infra "gcp"
    ;;
  *)
    print_error "Invalid option. Use 'help' to see available commands."
    help
    ;;
esac
