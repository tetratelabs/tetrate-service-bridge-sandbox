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
SUPPORTED_REGIONAL_ADDONS=("argocd" "fluxcd" "external-dns")
SUPPORTED_MP_ADDONS=("tsb-monitoring")

# Validate input values.
SUPPORTED_ACTIONS=("help"
                   "argocd_aws" "argocd_azure" "argocd_gcp"
                   "fluxcd_aws" "fluxcd_azure" "fluxcd_gcp" 
                   "external_dns_aws" "external_dns_azure" "external_dns_gcp" 
                   "tsb_monitoring"
                   "destroy_argocd_aws" "destroy_argocd_azure" "destroy_argocd_gcp"
                   "destroy_fluxcd_aws" "destroy_fluxcd_azure" "destroy_fluxcd_gcp"
                   "destroy_external_dns_aws" "destroy_external_dns_azure" "destroy_external_dns_gcp"
                   "destroy_tsb_monitoring")
if ! [[ " ${SUPPORTED_ACTIONS[*]} " == *" ${ACTION} "* ]]; then
  print_error "Invalid action '${ACTION}'. Must be one of '${SUPPORTED_ACTIONS[*]}'."
  exit 1
fi

# This function provides help information for the script.
function help() {
  echo "Usage: $0 <command> [options]"
  echo "Commands:"
  echo "  help                            Display this help message."
  echo "  argocd_aws                      Deploy addon argocd on aws."
  echo "  argocd_azure                    Deploy addon argocd on azure."
  echo "  argocd_gcp                      Deploy addon argocd on gcp."
  echo "  fluxcd_aws                      Deploy addon fluxcd on aws."
  echo "  fluxcd_azure                    Deploy addon fluxcd on azure."
  echo "  fluxcd_gcp                      Deploy addon fluxcd on gcp."
  echo "  tsb_monitoring                  Deploy addon tsb_monitoring."
  echo "  external_dns_aws                Deploy addon external_dns on aws."
  echo "  external_dns_azure              Deploy addon external_dns on azure."
  echo "  external_dns_gcp                Deploy addon external_dns on gcp."
  echo "  destroy_argocd_aws              Destroy addon argocd on aws."
  echo "  destroy_argocd_azure            Destroy addon argocd on azure."
  echo "  destroy_argocd_gcp              Destroy addon argocd on gcp."
  echo "  destroy_fluxcd_aws              Destroy addon fluxcd on aws."
  echo "  destroy_fluxcd_azure            Destroy addon fluxcd on azure."
  echo "  destroy_fluxcd_gcp              Destroy addon fluxcd on gcp."
  echo "  destroy_tsb_monitoring          Destroy addon tsb_monitoring."
  echo "  destroy_external_dns_aws        Destroy addon external_dns on aws."
  echo "  destroy_external_dns_azure      Destroy addon external_dns on azure."
  echo "  destroy_external_dns_gcp        Destroy addon external_dns on gcp."
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
case "${ACTION}" in
  help)
    help
    ;;
  argocd_aws)
    print_stage "Going to deploy addon 'argocd' on cloud 'aws'" 
    deploy_addon_per_region "aws" "argocd"
    ;;
  argocd_azure)
    print_stage "Going to deploy addon 'argocd' on cloud 'azure'" 
    deploy_addon_per_region "azure" "argocd"
    ;;
  argocd_gcp)
    print_stage "Going to deploy addon 'argocd' on cloud 'gcp'" 
    deploy_addon_per_region "gcp" "argocd"
    ;;
  fluxcd_aws)
    print_stage "Going to deploy addon 'fluxcd' on cloud 'aws'" 
    deploy_addon_per_region "aws" "fluxcd"
    ;;
  fluxcd_azure)
    print_stage "Going to deploy addon 'fluxcd' on cloud 'azure'" 
    deploy_addon_per_region "azure" "fluxcd"
    ;;
  fluxcd_gcp)
    print_stage "Going to deploy addon 'fluxcd' on cloud 'gcp'" 
    deploy_addon_per_region "gcp" "fluxcd"
    ;;
  tsb_monitoring)
    print_stage "Going to deploy addon 'tsb-monitoring'" 
    deploy_addon_mp_cluster "tsb-monitoring"
    ;;
  external_dns_aws)
    print_stage "Going to deploy addon 'external-dns' on cloud 'aws'" 
    deploy_addon_per_region "aws" "external-dns"
    ;;
  external_dns_azure)
    print_stage "Going to deploy addon 'external-dns' on cloud 'azure'" 
    deploy_addon_per_region "azure" "external-dns"
    ;;
  external_dns_gcp)
    print_stage "Going to deploy addon 'external-dns' on cloud 'gcp'" 
    deploy_addon_per_region "gcp" "external-dns"
    ;;
  destroy_argocd_aws)
    print_stage "Going to destroy addon 'argocd' on cloud 'aws'" 
    destroy_addon_per_region "aws" "argocd"
    ;;
  destroy_argocd_azure)
    print_stage "Going to destroy addon 'argocd' on cloud 'azure'" 
    destroy_addon_per_region "azure" "argocd"
    ;;
  destroy_argocd_gcp)
    print_stage "Going to destroy addon 'argocd' on cloud 'gcp'" 
    destroy_addon_per_region "gcp" "argocd"
    ;;
  destroy_fluxcd_aws)
    print_stage "Going to destroy addon 'fluxcd' on cloud 'aws'" 
    destroy_addon_per_region "aws" "fluxcd"
    ;;
  destroy_fluxcd_azure)
    print_stage "Going to destroy addon 'fluxcd' on cloud 'azure'" 
    destroy_addon_per_region "azure" "fluxcd"
    ;;
  destroy_fluxcd_gcp)
    print_stage "Going to destroy addon 'fluxcd' on cloud 'gcp'" 
    destroy_addon_per_region "gcp" "fluxcd"
    ;;
  destroy_tsb_monitoring)
    print_stage "Going to destroy addon 'tsb-monitoring'" 
    destroy_addon_mp_cluster "tsb-monitoring"
    ;;
  destroy_external_dns_aws)
    print_stage "Going to destroy addon 'external-dns' on cloud 'aws'" 
    destroy_addon_per_region "aws" "external-dns"
    ;;
  destroy_external_dns_azure)
    print_stage "Going to destroy addon 'external-dns' on cloud 'azure'" 
    destroy_addon_per_region "azure" "external-dns"
    ;;
  destroy_external_dns_gcp)
    print_stage "Going to destroy addon 'external-dns' on cloud 'gcp'" 
    destroy_addon_per_region "gcp" "external-dns"
    ;;
  *)
    print_error "Invalid option. Use 'help' to see available commands."
    help
    ;;
esac