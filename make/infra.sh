#!/usr/bin/env bash
#
# Helper script to deploy and destroy cloud infra (including k8s)
#
BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export BASE_DIR

source "${BASE_DIR}/helpers.sh"

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
#
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
function deploy_infra() {
  if [[ -z "${1}" ]] ; then print_error "Please provide cloud provider as 1st argument" ; return 1 ; else local cloud="${1}" ; fi
  if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${cloud} "* ]]; then print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'." ; return 1 ; fi

  print_info "Going to deploy infra on cloud '${cloud}'"
  set -e

  # Get the number of clusters for the specified cloud provider.
  local cluster_count=$(get_cluster_count "${TFVARS_JSON}" "${cloud}")

  for ((index = 0; index < cluster_count; index++)); do
    local cluster=$(get_cluster_config "${TFVARS_JSON}" "${cloud}" "${index}")
    local workspace=$(get_cluster_workspace "${cluster}")
    echo "Processing cluster:" 
    echo "${cluster}" | jq '.'

    run "pushd infra/${cloud} > /dev/null"
    run "terraform workspace new ${workspace} || true"
    run "terraform workspace select ${workspace}"
    run "terraform init"
    run "terraform apply ${TERRAFORM_APPLY_ARGS} -target module.${cloud}_base -var-file=../../${TFVARS_JSON} -var=cluster='${cluster}'"
    run "terraform apply ${TERRAFORM_APPLY_ARGS} -var-file=../../${TFVARS_JSON} -var=cluster='${cluster}'"
    run "terraform output ${TERRAFORM_OUTPUT_ARGS} | jq . > ../../outputs/terraform_outputs/terraform-${workspace}.json"
    run "terraform workspace select default"
    run "popd > /dev/null"
  done

  print_info "Finished deploying infra on cloud '${cloud}'"
}

# This function destroys infra on the specified cloud provider.
#
function destroy_infra() {
  if [[ -z "${1}" ]] ; then print_error "Please provide cloud provider as 1st argument" ; return 1 ; else local cloud="${1}" ; fi
  if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${cloud} "* ]]; then print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'." ; return 1 ; fi

  print_info "Going to destroy infra on cloud '${cloud}'"

  # Get the number of clusters for the specified cloud provider.
  local cluster_count=$(get_cluster_count "${TFVARS_JSON}" "${cloud}")

  for ((index = 0; index < cluster_count; index++)); do
    local cluster=$(get_cluster_config "${TFVARS_JSON}" "${cloud}" "${index}")
    local workspace=$(get_cluster_workspace "${cluster}")
    echo "Processing cluster:" 
    echo "${cluster}" | jq '.'

    run "pushd infra/${cloud} > /dev/null"
    run "terraform workspace select ${workspace}"
    run "terraform destroy ${TERRAFORM_DESTROY_ARGS} -var-file=../../${TFVARS_JSON} -var=cluster='${cluster}'"
    run "terraform workspace select default"
    run "terraform workspace delete ${TERRAFORM_WORKSPACE_ARGS} ${workspace}"
    run "popd > /dev/null"
  done

  print_info "Finished destroying infra on cloud '${cloud}'"
}

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