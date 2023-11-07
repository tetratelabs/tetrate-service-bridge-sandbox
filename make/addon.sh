#!/usr/bin/env bash
#
# Helper script for addons: deploy and destroy of argocd, fluxcd, tsb-monitoring and external-dns.
BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export BASE_DIR

# shellcheck source=/dev/null
source "${BASE_DIR}/helpers.sh"
# shellcheck source=/dev/null
source "${BASE_DIR}/variables.sh"

ACTION=${1}
SUPPORTED_CLOUDS=("azure" "aws" "gcp")
SUPPORTED_ADDONS=("argocd" "fluxcd" "external-dns" "tsb_monitoring")

# Generate SUPPORTED_ACTIONS based on patterns.
SUPPORTED_ACTIONS=("help")
for addon in "${SUPPORTED_ADDONS[@]::3}"; do
  for cloud in "${SUPPORTED_CLOUDS[@]}"; do
    SUPPORTED_ACTIONS+=("${addon}_${cloud}" "destroy_${addon}_${cloud}")
  done
done

# Validate input values.
if ! [[ " ${SUPPORTED_ACTIONS[*]} " =~ " ${ACTION} " ]]; then
  echo "Invalid action '${ACTION}'. Must be one of ${SUPPORTED_ACTIONS[*]}."
  exit 1
fi

# This function provides help information for the script.
help() {
  echo "Usage: $0 <command> [options]"
  echo "Commands:"
  echo "  help                            Display this help message."
  for addon in "${SUPPORTED_ADDONS[@]}"; do
    if [[ " ${SUPPORTED_CLOUDS[*]} " =~ " ${addon} " ]]; then
      for cloud in "${SUPPORTED_CLOUDS[@]}"; do
        echo "  ${addon}_${cloud}                    Deploy addon ${addon} on ${cloud}."
        echo "  destroy_${addon}_${cloud}            Destroy addon ${addon} on ${cloud}."
      done
    else
      echo "  ${addon}                        Deploy addon ${addon}."
      echo "  destroy_${addon}                Destroy addon ${addon}."
    fi
  done
}

# This function deploys the specified addon on the specified cloud provider per region.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#   $2 - The addon name ("argocd", "fluxcd" or "external-dns").
#
# Usage: deploy_addon_per_region "azure" "argocd"
function deploy_addon_per_region() {
  if [[ -z "${1}" ]] ; then print_error "Please provide cloud provider as 1st argument" ; return 1 ; else local cloud="${1}" ; fi
  if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${cloud} "* ]]; then print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'." ; return 1 ; fi
  [[ -z "${2}" ]] && print_error "Please provide regional addon name as 2nd argument" && return 1 || local addon_name="${2}" ;
  if ! [[ " ${SUPPORTED_REGIONAL_ADDONS[*]} " == *" ${addon_name} "* ]]; then print_error "Invalid regional addon. Must be one of '${SUPPORTED_REGIONAL_ADDONS[*]}'." ; return 1 ; fi

  print_info "Going to deploy regional addon '${addon_name}' on cloud '${cloud}'"
  source "${BASE_DIR}/k8s_auth.sh" k8s_auth_${cloud}
  set -e

  # Get the number of clusters for the specified cloud provider.
  local cluster_count=$(get_cluster_count "${TFVARS_JSON}" "${cloud}")

  for ((index = 0; index < cluster_count; index++)); do
    local cluster=$(get_cluster_config "${TFVARS_JSON}" "${cloud}" "${index}")
    local workspace=$(get_cluster_workspace "${cluster}")
    echo processing cluster: "${cluster}"

    if [[ $(is_cluster_addon_enabled "${cluster}" ${addon_name}) == false ]] ; then continue ; fi
    addon_config=$(get_cluster_addon_config "${cluster}" ${addon_name})
    if [[ "${addon_name}" == "external-dns" ]]; then
      run "pushd addons/${addon_name}/${cloud} > /dev/null"
      root_path="../../.."
    else
      run "pushd addons/${addon_name} > /dev/null"
      root_path="../.."
    fi
    run "terraform workspace new ${workspace} || true"
    run "terraform workspace select ${workspace}"
    run "terraform init"
    run "terraform apply ${TERRAFORM_APPLY_ARGS} -var-file=${root_path}/${TFVARS_JSON} -var=cluster='${cluster}' -var=addon_config='${addon_config}'"
    run "terraform output ${TERRAFORM_OUTPUT_ARGS} | jq . > ${root_path}/outputs/terraform_outputs/terraform-${workspace}.json"
    run "terraform workspace select default"
    run "popd > /dev/null"
  done

  print_info "Finished deploying regional addon '${addon_name}' on cloud '${cloud}'"
}

# This function deploys the specified addon in the management plane cluster.
#
# Parameters:
#   $1 - The addon name ("tsb-monitoring").
#
# Usage: deploy_addon_mp_cluster "tsb-monitoring"
function deploy_addon_mp_cluster() {
  [[ -z "${1}" ]] && print_error "Please provide global addon name as 1st argument" && return 1 || local addon_name="${1}" ;
  if ! [[ " ${SUPPORTED_MP_ADDONS[*]} " == *" ${addon_name} "* ]]; then print_error "Invalid global addon. Must be one of '${SUPPORTED_MP_ADDONS[*]}'." ; return 1 ; fi
  
  local cluster=$(get_mp_cluster_config "${TFVARS_JSON}")
  local cloud=$(get_cluster_cloud "${cluster}")
  local workspace=$(get_cluster_workspace "${cluster}")
  echo processing cluster: "${cluster}"

  if [[ $(is_cluster_addon_enabled "${cluster}" ${addon_name}) == false ]] ; then return ; fi
  addon_config=$(get_cluster_addon_config "${cluster}" ${addon_name})
  source "${BASE_DIR}/k8s_auth.sh" k8s_auth_${cloud}
  print_info "Going to deploy management cluster addon '${addon_name}'"
  set -e

  run "pushd addons/${addon_name} > /dev/null"
  run "terraform workspace new ${workspace} || true"
  run "terraform workspace select ${workspace}"
  run "terraform init"
  run "terraform apply ${TERRAFORM_APPLY_ARGS} -var-file=../../${TFVARS_JSON} -var=cluster='${cluster}' -var=addon_config='${addon_config}'"
  run "terraform output ${TERRAFORM_OUTPUT_ARGS} | jq . > ../../outputs/terraform_outputs/terraform-${addon_name}.json"
  run "terraform workspace select default"
  run "popd > /dev/null"

  print_info "Finished deploying management cluster addon '${addon_name}'"
}

# This function destroy the specified addon on the specified cloud provider per region.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#   $2 - The addon name ("argocd", "fluxcd" or "external-dns").
#
# Usage: destroy_addon_per_region "azure" "argocd"
function destroy_addon_per_region() {
  if [[ -z "${1}" ]] ; then print_error "Please provide cloud provider as 1st argument" ; return 1 ; else local cloud="${1}" ; fi
  if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${cloud} "* ]]; then print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'." ; return 1 ; fi
  [[ -z "${2}" ]] && print_error "Please provide regional addon name as 2nd argument" && return 1 || local addon_name="${2}" ;
  if ! [[ " ${SUPPORTED_REGIONAL_ADDONS[*]} " == *" ${addon_name} "* ]]; then print_error "Invalid regional addon. Must be one of '${SUPPORTED_REGIONAL_ADDONS[*]}'." ; return 1 ; fi

  print_info "Going to destroy regional addon '${addon_name}' on cloud '${cloud}'"
  source "${BASE_DIR}/k8s_auth.sh" k8s_auth_${cloud}
  set -e

  # Get the number of clusters for the specified cloud provider.
  local cluster_count=$(get_cluster_count "${TFVARS_JSON}" "${cloud}")

  for ((index = 0; index < cluster_count; index++)); do
    local cluster=$(get_cluster_config "${TFVARS_JSON}" "${cloud}" "${index}")
    local workspace=$(get_cluster_workspace "${cluster}")
    echo processing cluster: "${cluster}"

    if [[ $(is_cluster_addon_enabled "${cluster}" ${addon_name}) == false ]] ; then continue ; fi
    addon_config=$(get_cluster_addon_config "${cluster}" ${addon_name})
    if [[ "${addon_name}" == "external-dns" ]]; then
      run "pushd addons/${addon_name}/${cloud} > /dev/null"
      root_path="../../.."
    else
      run "pushd addons/${addon_name} > /dev/null"
      root_path="../.."
    fi
    run "terraform workspace new ${workspace} || true"
    run "terraform workspace select ${workspace}"
    run "terraform init"
    run "terraform destroy ${TERRAFORM_DESTROY_ARGS} -var-file=${root_path}/${TFVARS_JSON} -var=cluster='${cluster}' -var=addon_config='${addon_config}'"
    run "terraform workspace select default"
    run "terraform workspace delete ${TERRAFORM_WORKSPACE_ARGS} ${workspace}"
    run "popd > /dev/null"
  done

  print_info "Finished destroying regional addon '${addon_name}' on cloud '${cloud}'"
}

# This function destroys the specified addon in the management plane cluster.
#
# Parameters:
#   $1 - The addon name ("tsb-monitoring").
#
# Usage: destroy_addon_mp_cluster "tsb-monitoring"
function destroy_addon_mp_cluster() {
  [[ -z "${1}" ]] && print_error "Please provide regional addon name as 1st argument" && return 1 || local addon_name="${1}" ;
  if ! [[ " ${SUPPORTED_MP_ADDONS[*]} " == *" ${addon_name} "* ]]; then print_error "Invalid global addon. Must be one of '${SUPPORTED_MP_ADDONS[*]}'." ; return 1 ; fi

  local cluster=$(get_mp_cluster_config "${TFVARS_JSON}")
  local cloud=$(get_cluster_cloud "${cluster}")
  local workspace=$(get_cluster_workspace "${cluster}")
  echo processing cluster: "${cluster}"

  if [[ $(is_cluster_addon_enabled "${cluster}" ${addon_name}) == false ]] ; then return ; fi
  addon_config=$(get_cluster_addon_config "${cluster}" ${addon_name})
  source "${BASE_DIR}/k8s_auth.sh" k8s_auth_${cloud}
  print_info "Going to destroy management cluster addon '${addon_name}'"
  set -e

  run "pushd addons/${addon_name} > /dev/null"
  run "terraform workspace select ${workspace}"
  run "terraform init"
  run "terraform destroy ${TERRAFORM_DESTROY_ARGS} -var-file=../../${TFVARS_JSON} -var=cluster='${cluster}' -var=addon_config='${addon_config}'"
  run "terraform workspace select default"
  run "popd > /dev/null"

  print_info "Finished destroying management cluster addon '${addon_name}'"
}


#
# Main execution.
#

# Switch case to handle actions
case "${ACTION}" in
  help)
    help
    ;;
  argocd_aws | argocd_azure | argocd_gcp | \
  fluxcd_aws | fluxcd_azure | fluxcd_gcp | \
  external_dns_aws | external_dns_azure | external_dns_gcp)
    CLOUD="${ACTION##*_}"
    ADDON="${ACTION%_*}"
    print_stage "Going to deploy addon $ADDON on cloud $CLOUD"
    deploy_addon_per_region "$CLOUD" "$ADDON"
    ;;
  destroy_argocd_aws | destroy_argocd_azure | destroy_argocd_gcp | \
  destroy_fluxcd_aws | destroy_fluxcd_azure | destroy_fluxcd_gcp | \
  destroy_external_dns_aws | destroy_external_dns_azure | destroy_external_dns_gcp)
    CLOUD="${ACTION##*_}"
    ADDON="destroy_${ACTION%_*}"
    ADDON="${ADDON#destroy_}"
    print_stage "Going to destroy addon $ADDON on cloud $CLOUD"
    destroy_addon_per_region "$CLOUD" "$ADDON"
    ;;
  tsb_monitoring)
    print_stage "Going to deploy addon 'tsb-monitoring'"
    deploy_addon_mp_cluster "tsb-monitoring"
    ;;
  destroy_tsb_monitoring)
    print_stage "Going to destroy addon 'tsb-monitoring'"
    destroy_addon_mp_cluster "tsb-monitoring"
    ;;
  *)
    print_error "Invalid option. Use 'help' to see available commands."
    help
    ;;
esac