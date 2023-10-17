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
SUPPORTED_GLOBAL_ADDONS=("tsb-monitoring")

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
  if [[ -z "${1}" ]] ; then print_error "Please provide cloud provider as 1st argument" ; return 1 ; else local cloud_provider="${1}" ; fi
  if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${cloud_provider} "* ]]; then print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'." ; return 1 ; fi
  [[ -z "${2}" ]] && print_error "Please provide regional addon name as 2nd argument" && return 1 || local addon_name="${2}" ;
  if ! [[ " ${SUPPORTED_REGIONAL_ADDONS[*]} " == *" ${addon_name} "* ]]; then print_error "Invalid regional addon. Must be one of '${SUPPORTED_REGIONAL_ADDONS[*]}'." ; return 1 ; fi

  print_info "Going to deploy regional addon '${addon_name}' on cloud '${cloud_provider}'"
  set -e

  local index=0

  while read -r region; do
    cluster_name="${cloud_provider}-${name_prefix}-${region}-${index}"
    echo cloud="${cloud_provider} region=${region} cluster_id=${index} cluster_name=${cluster_name}"

    if [[ "${addon_name}" == "external-dns" ]]; then
      run_or_print "pushd addons/${cloud_provider}/${addon_name} > /dev/null"
      root_path="../../.."
    else
      run_or_print "pushd addons/${addon_name} > /dev/null"
      root_path="../.."
    fi
    run_or_print "terraform workspace new ${cloud_provider}-${index}-${region} || true"
    run_or_print "terraform workspace select ${cloud_provider}-${index}-${region}"
    run_or_print "terraform init"
    run_or_print "terraform apply ${TERRAFORM_APPLY_ARGS} -var-file=${root_path}/${TFVARS_JSON} -var=cloud=${cloud_provider} -var=cluster_id=${index}"
    run_or_print "terraform output ${TERRAFORM_OUTPUT_ARGS} | jq . > ${root_path}/outputs/terraform_outputs/terraform-${addon_name}-${cloud}-${index}.json"
    run_or_print "terraform workspace select default"
    run_or_print "popd > /dev/null"
    
    index=$((index+1))
  done < <(jq -r ".${cloud_provider}_k8s_regions[]" "${TFVARS_JSON}")

  print_info "Finished deploying regional addon '${addon_name}' on cloud '${cloud_provider}'"
}

# This function deploys the specified addon globally.
#
# Parameters:
#   $1 - The addon name ("tsb-monitoring").
#
# Usage: deploy_addon_global "tsb-monitoring"
function deploy_addon_global() {
  [[ -z "${1}" ]] && print_error "Please provide regional addon name as 1st argument" && return 1 || local addon_name="${1}" ;
  if ! [[ " ${SUPPORTED_GLOBAL_ADDONS[*]} " == *" ${addon_name} "* ]]; then print_error "Invalid global addon. Must be one of '${SUPPORTED_GLOBAL_ADDONS[*]}'." ; return 1 ; fi

  print_info "Going to deploy global addon '${addon_name}'"
  set -e

  run_or_print "pushd addons/${addon_name} > /dev/null"
  run_or_print "terraform workspace select default"
  run_or_print "terraform init"
  run_or_print "terraform apply ${TERRAFORM_APPLY_ARGS} -var-file=../../${TFVARS_JSON}"
  run_or_print "terraform output ${TERRAFORM_OUTPUT_ARGS} | jq . > ../../outputs/terraform_outputs/terraform-${addon_name}.json"
  run_or_print "terraform workspace select default"
  run_or_print "popd > /dev/null"

  print_info "Finished deploying global addon '${addon_name}'"
}

# This function destroy the specified addon on the specified cloud provider per region.
#
# Parameters:
#   $1 - The cloud provider ("azure", "aws", or "gcp").
#   $2 - The addon name ("argocd", "fluxcd" or "external-dns").
#
# Usage: destroy_addon_per_region "azure" "argocd"
function destroy_addon_per_region() {
  if [[ -z "${1}" ]] ; then print_error "Please provide cloud provider as 1st argument" ; return 1 ; else local cloud_provider="${1}" ; fi
  if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${cloud_provider} "* ]]; then print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'." ; return 1 ; fi
  [[ -z "${2}" ]] && print_error "Please provide regional addon name as 2nd argument" && return 1 || local addon_name="${2}" ;
  if ! [[ " ${SUPPORTED_REGIONAL_ADDONS[*]} " == *" ${addon_name} "* ]]; then print_error "Invalid regional addon. Must be one of '${SUPPORTED_REGIONAL_ADDONS[*]}'." ; return 1 ; fi

  print_info "Going to destroy regional addon '${addon_name}' on cloud '${cloud_provider}'"
  set -e

  local index=0

  while read -r region; do
    cluster_name="${cloud_provider}-${name_prefix}-${region}-${index}"
    echo cloud="${cloud_provider} region=${region} cluster_id=${index} cluster_name=${cluster_name}"

    if [[ "${addon_name}" == "external-dns" ]]; then
      run_or_print "pushd addons/${cloud_provider}/${addon_name} > /dev/null"
      root_path="../../.."
    else
      run_or_print "pushd addons/${addon_name} > /dev/null"
      root_path="../.."
    fi
    run_or_print "terraform workspace new ${cloud_provider}-${index}-${region} || true"
    run_or_print "terraform workspace select ${cloud_provider}-${index}-${region}"
    run_or_print "terraform init"
    run_or_print "terraform destroy ${TERRAFORM_DESTROY_ARGS} -var-file=${root_path}/${TFVARS_JSON} -var=cloud=${cloud_provider} -var=cluster_id=${index}"
    run_or_print "terraform workspace select default"
    run_or_print "terraform workspace delete ${TERRAFORM_WORKSPACE_ARGS} ${cloud_provider}-${index}-${region}"
    run_or_print "popd > /dev/null"

    index=$((index+1))
  done < <(jq -r ".${cloud_provider}_k8s_regions[]" "${TFVARS_JSON}")

  print_info "Finished destroying regional addon '${addon_name}' on cloud '${cloud_provider}'"

}


# This function destroys the specified addon globally.
#
# Parameters:
#   $1 - The addon name ("tsb-monitoring").
#
# Usage: destroy_addon_global "tsb-monitoring"
function destroy_addon_global() {
  [[ -z "${1}" ]] && print_error "Please provide regional addon name as 1st argument" && return 1 || local addon_name="${1}" ;
  if ! [[ " ${SUPPORTED_GLOBAL_ADDONS[*]} " == *" ${addon_name} "* ]]; then print_error "Invalid global addon. Must be one of '${SUPPORTED_GLOBAL_ADDONS[*]}'." ; return 1 ; fi

  print_info "Going to destroy global addon '${addon_name}'"
  set -e

  run_or_print "pushd addons/${addon_name} > /dev/null"
  run_or_print "terraform workspace select default"
  run_or_print "terraform init"
  run_or_print "terraform destroy ${TERRAFORM_DESTROY_ARGS} -var-file=../../${TFVARS_JSON}"
  run_or_print "terraform workspace select default"
  run_or_print "popd > /dev/null"

  print_info "Finished destroying global addon '${addon_name}'"
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
    deploy_addon_global "tsb-monitoring"
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
    destroy_addon_global "tsb-monitoring"
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
