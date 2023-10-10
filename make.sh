
#!/usr/bin/env bash
#
# Helper script to avoid makefile escaping and other shenanigans
#
export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

JSON_TFVARS="terraform.aws.tfvars.json"
TERRAFORM_APPLY_ARGS="-compact-warnings -auto-approve"
TERRAFORM_DESTROY_ARGS="-compact-warnings -auto-approve"
TERRAFORM_WORKSPACE_ARGS="-force"
TERRAFORM_OUTPUT_ARGS="-json"


# Helper print functions

BLUEB="\033[1;34m"
END="\033[0m"
GREENB="\033[1;32m"
PURPLEB="\033[1;35m"
REDB="\033[1;31m"
YELLOWB="\033[1;33m"


function print_info() {
  echo -e "${GREENB}${1}${END}"
}

function print_error() {
  echo -e "${REDB}${1}${END}"
}

function print_stage() {
  echo -e "${BLUEB}***************************************** ${1} *****************************************${END}"
}

# print_terraform: Prints the provided Terraform information in a formatted manner.
#
# Arguments:
#   module_path:     The path to the Terraform module.
#   workspace_name:  The name of the Terraform workspace.
#   extra_vars:      Any additional variables to be passed to Terraform.
#   output_file:     The file where Terraform output will be saved.
#
# Outputs:
#   Prints the Terraform information in a formatted manner.
#
# Usage:
#   print_terraform "/path/to/module" "my_workspace" "-var=value" "output.txt"
#
function print_terraform() {
  local module_path=${1}
  local workspace_name=${2}
  local extra_vars=${3}
  local output_file=${4}

  echo -e "${YELLOWB}
----------------------------------------------------------------------------------------------------
Module path:    ${module_path}
Workspace name: ${workspace_name}
Extra vars:     ${extra_vars}
Output file:    ${output_file}
----------------------------------------------------------------------------------------------------
${END}"
}

# Enable debug
# set -o xtrace

function validate_json_structure() {
  if ! jq -e '.cp_clusters[] | select(.cloud_provider and .name and .region and .version and .zones)' "$JSON_TFVARS" > /dev/null; then
    print_error "Invalid structure in 'cp_clusters'. Ensure each cluster has 'cloud_provider', 'name', 'region', 'version', and 'zones'."
    return 1
  fi
  if ! jq -e '.dns_provider | select(. == "aws" or . == "gcp" or . == "azure")' "$JSON_TFVARS" > /dev/null; then
    print_error "Invalid 'dns_provider' value. It should be 'aws', 'gcp', or 'azure'."
    return 1
  fi
  if ! jq -e '.mp_cluster | select(.cloud_provider and .name and .region and .version and .zones)' "$JSON_TFVARS" > /dev/null; then
    print_error "Invalid structure in 'mp_cluster'. Ensure it has 'cloud_provider', 'name', 'region', 'version', and 'zones'."
    return 1
  fi
  if ! jq -e '.name_prefix' "$JSON_TFVARS" > /dev/null; then
    print_error "Missing 'name_prefix' in the JSON."
    return 1
  fi
  if ! jq -e '.tsb | select(.fqdn and .image_sync_apikey and .image_sync_username and .organisation and .password and .version)' "$JSON_TFVARS" > /dev/null; then
    print_error "Invalid structure in 'tsb'. Ensure it has 'fqdn', 'image_sync_apikey', 'image_sync_username', 'organisation', 'password', and 'version'."
    return 1
  fi
  if ! jq -e '.cp_clusters[] | select(.cloud_provider == "aws" or .cloud_provider == "gcp" or .cloud_provider == "azure")' "$JSON_TFVARS" > /dev/null; then
    print_error "Invalid 'cloud_provider' value in 'cp_clusters'. It should be 'aws', 'gcp', or 'azure'."
    return 1
  fi
  if ! jq -e '.mp_cluster | select(.cloud_provider == "aws" or .cloud_provider == "gcp" or .cloud_provider == "azure")' "$JSON_TFVARS" > /dev/null; then
    print_error "Invalid 'cloud_provider' value in 'mp_cluster'. It should be 'aws', 'gcp', or 'azure'."
    return 1
  fi
  print_info "JSON structure is valid."
}


function deploy_k8s_clusters() {
  set -e
  local index=0
  local name_prefix=$(jq -r '.name_prefix' ${JSON_TFVARS})

  # Process both mp_cluster (index 0) and cp_clusters (index 1...n)
  for cluster_type in mp_cluster cp_clusters; do
    if [ "${cluster_type}" == "mp_cluster" ]; then
      local clusters=$(jq -c ".${cluster_type}" ${JSON_TFVARS})
    else
      local clusters=$(jq -c ".${cluster_type}[]" ${JSON_TFVARS})
    fi
    if [ -z "${clusters}" ]; then continue; fi

    while read -r cluster; do
      local region=$(echo "${cluster}" | jq -r '.region')
      local k8s_version=$(echo "${cluster}" | jq -r '.version')
      local cloud_provider=$(echo "${cluster}" | jq -r '.cloud_provider')
      local cluster_name=""
      local name_from_json=$(echo "${cluster}" | jq -r '.name')
      # [backwards compatibility] if name not set or empty, fall back to previous naming convention
      if [ -n "${name_from_json}" ] && [ "${name_from_json}" != "null" ]; then
        cluster_name="${cloud_provider}-${name_from_json}"
      else 
        cluster_name="${cloud_provider}-${name_prefix}-${region}-${index}"
      fi
      # [todo] zones is not implemented yet
      local zones=$(echo "${cluster}" | jq -r '.zones | join(",")')
      print_info "cloud=${cloud_provider} region=${region} zones=${zones} cluster_id=${index} cluster_name=${cluster_name}"
      print_terraform "infra/${cloud_provider}" \
                      "${cloud_provider}-${index}-${region}" \
                      "-var=${cloud_provider}_k8s_region=${region} -var=cluster_name=${cluster_name} -var=cluster_id=${index} -var=${cloud_provider}_k8s_version=${k8s_version}" \
                      "outputs/terraform_outputs/terraform-${cloud_provider}-${cluster_name}-${index}.json"

      cd "infra/${cloud_provider}"
      terraform workspace new ${cloud_provider}-${index}-${region} || true
      terraform workspace select ${cloud_provider}-${index}-${region}
      terraform init
      terraform apply ${TERRAFORM_APPLY_ARGS} -target module.${cloud_provider}_base -var-file="../../${JSON_TFVARS}" -var=${cloud_provider}_k8s_region=${region} -var=cluster_name=${cluster_name} -var=cluster_id=${index} -var=${cloud_provider}_k8s_version=${k8s_version}
      terraform apply ${TERRAFORM_APPLY_ARGS} -var-file="../../${JSON_TFVARS}" -var=${cloud_provider}_k8s_region=${region} -var=cluster_name=${cluster_name} -var=cluster_id=${index} -var=${cloud_provider}_k8s_version=${k8s_version}
      terraform output ${TERRAFORM_OUTPUT_ARGS} | jq . > ../../outputs/terraform_outputs/terraform-${cloud_provider}-${cluster_name}-${index}.json
      terraform workspace select default

      index=$((index+1))
      cd "../.."
    done < <(echo "${clusters}")
  done
}

function deploy_k8s_auths() {
  set -e
  local cloud_provider=${1}
  local index=0
  local name_prefix=$(jq -r '.name_prefix' ${JSON_TFVARS})

  # Process both mp_cluster (index 0) and cp_clusters (index 1...n)
  for cluster_type in mp_cluster cp_clusters; do
    if [ "${cluster_type}" == "mp_cluster" ]; then
      local clusters=$(jq -c ".${cluster_type}" ${JSON_TFVARS})
    else
      local clusters=$(jq -c ".${cluster_type}[]" ${JSON_TFVARS})
    fi
    if [ -z "${clusters}" ]; then continue; fi

    while read -r cluster; do
      local region=$(echo "${cluster}" | jq -r '.region')
      local cloud_provider=$(echo "${cluster}" | jq -r '.cloud_provider')
      local cluster_name=""
      local name_from_json=$(echo "${cluster}" | jq -r '.name')
      # [backwards compatibility] if name not set or empty, fall back to previous naming convention
      if [ -n "${name_from_json}" ] && [ "${name_from_json}" != "null" ]; then
        cluster_name="${cloud_provider}-${name_from_json}"
      else 
        cluster_name="${cloud_provider}-${name_prefix}-${region}-${index}"
      fi
      print_info "cloud=${cloud_provider} region=${region} cluster_id=${index} cluster_name=${cluster_name}"
      print_terraform "infra/${cloud_provider}/k8s_auth" \
                      "${cloud_provider}-${index}-${region}" \
                      "-var="${cloud_provider}_k8s_region=${region}" -var=cluster_id=${index}" \
                      " "

      cd "infra/${cloud_provider}/k8s_auth"
      terraform workspace new "${cloud_provider}-${index}-${region}" || true
      terraform workspace select "${cloud_provider}-${index}-${region}"
      terraform init
      terraform apply -refresh=false ${TERRAFORM_APPLY_ARGS} -var-file="../../../${JSON_TFVARS}" -var="${cloud_provider}_k8s_region=${region}" -var=cluster_id=${index}
      terraform workspace select default

      index=$((index+1))
      cd "../../.."
    done < <(echo "${clusters}")
  done
}

function deploy_tsb_mp() {
  set -e
  local cloud_provider=$(jq -r '.mp_cluster.cloud_provider' ${JSON_TFVARS})
  local region=$(jq -r '.mp_cluster.region' ${JSON_TFVARS})
  local cluster_name=$(jq -r '.mp_cluster.name' ${JSON_TFVARS})
  local dns_provider=$(jq -r '.dns_provider' ${JSON_TFVARS})
  local index=0
  if [ "${dns_provider}" == "null" ] || [ -z "${dns_provider}" ] ; then
    # TODO: review this logic
    dns_provider=$(jq -r '.tsb.fqdn' ${JSON_TFVARS} | cut -d"." -f2 | sed 's/sandbox/gcp/g')
  fi
  print_info "cloud=${cloud_provider} region=${region} cluster_id=0 cluster_name=${cluster_name}"
  print_terraform "tsb/mp" \
                  "default" \
                  "-var="cloud=${cloud_provider}" -var=cluster_id=${index} -var=cluster_region=${region} -var=cluster_name=${cluster_name}" \
                  "outputs/terraform_outputs/terraform-tsb-mp.json"

  cd "tsb/mp"
  terraform workspace select default
  terraform init
  terraform apply ${TERRAFORM_APPLY_ARGS} -target=module.cert-manager -target=module.es -target="data.terraform_remote_state.infra" -var-file="../../${JSON_TFVARS}" -var="cloud=${cloud_provider}" -var=cluster_id=${index} -var=cluster_region=${region} -var=cluster_name=${cluster_name}
  terraform apply ${TERRAFORM_APPLY_ARGS} -target=module.tsb_mp.kubectl_manifest.manifests_certs -target="data.terraform_remote_state.infra" -var-file="../../${JSON_TFVARS}" -var="cloud=${cloud_provider}" -var=cluster_id=${index} -var=cluster_region=${region} -var=cluster_name=${cluster_name}
  terraform apply ${TERRAFORM_APPLY_ARGS} -var-file="../../${JSON_TFVARS}" -var="cloud=${cloud_provider}" -var=cluster_id=${index} -var=cluster_region=${region} -var=cluster_name=${cluster_name}
  terraform output ${TERRAFORM_OUTPUT_ARGS} | jq . > ../../outputs/terraform_outputs/terraform-tsb-mp.json

  local fqdn=$(jq -r '.tsb.fqdn' ../../${JSON_TFVARS})
  local address=$(jq -r "if .ingress_ip.value != \"\" then .ingress_ip.value else .ingress_hostname.value end" ../../outputs/terraform_outputs/terraform-tsb-mp.json)

  print_terraform "tsb/fqdn/${dns_provider}" \
                  "default" \
                  "-var=address=${address} -var=fqdn=${fqdn}" \
                  " "

  terraform -chdir=../fqdn/${dns_provider} init
  terraform -chdir=../fqdn/${dns_provider} apply ${TERRAFORM_APPLY_ARGS} -var-file="../../../${JSON_TFVARS}" -var=address=${address} -var=fqdn=${fqdn}
  terraform workspace select default

  cd "../.."
}

function deploy_tsb_cps() {
  set -e
  local index=1 # index 0 was reserved for mp
  clusters=$(jq -c '.cp_clusters[]' ${JSON_TFVARS})

  while read -r cluster; do
    cloud_provider=$(echo $cluster | jq -r '.cloud_provider')
    cluster_name=$(echo $cluster | jq -r '.name')
    region=$(echo $cluster | jq -r '.region')
    version=$(echo $cluster | jq -r '.version')
    print_info "cloud=${cloud_provider} region=${region} cluster_id=${index} cluster_name=${cluster_name}"
    print_terraform "tsb/cp" \
                    "${cloud_provider}-${index}-${region}" \
                    "-var=cloud=${cloud_provider} -var=cluster_id=${index} -var=cluster_region=${region} -var=cluster_name=${cluster_name}" \
                    " "

    cd "tsb/cp"
    terraform workspace new ${cloud_provider}-${index}-${region} || true
    terraform workspace select ${cloud_provider}-${index}-${region}
    terraform init
    terraform apply ${TERRAFORM_APPLY_ARGS} -var-file="../../${JSON_TFVARS}" -var=cloud=${cloud_provider} -var=cluster_id=${index} -var=cluster_region=${region} -var=cluster_name=${cluster_name}
    terraform workspace select default

    index=$((index+1))
    cd "../.."
  done < <(echo "${clusters}")
}

function deploy_addon() {
  set -e
  local index=0
  local addon=${1}

  # Process both mp_cluster (index 0) and cp_clusters (index 1...n)
  for cluster_type in mp_cluster cp_clusters; do
    if [ "${cluster_type}" == "mp_cluster" ]; then
      local clusters=$(jq -c ".${cluster_type}" ${JSON_TFVARS})
    else
      local clusters=$(jq -c ".${cluster_type}[]" ${JSON_TFVARS})
    fi
    if [ -z "${clusters}" ]; then continue; fi

    while read -r cluster; do
      local region=$(echo "${cluster}" | jq -r '.region')
      local cloud_provider=$(echo "${cluster}" | jq -r '.cloud_provider')
      local cluster_name=""
      local name_from_json=$(echo "${cluster}" | jq -r '.name')
      # [backwards compatibility] if name not set or empty, fall back to previous naming convention
      if [ -n "${name_from_json}" ] && [ "${name_from_json}" != "null" ]; then
        cluster_name="${cloud_provider}-${name_from_json}"
      else 
        cluster_name="${cloud_provider}-${name_prefix}-${region}-${index}"
      fi
      print_info "cloud=${cloud_provider} region=${region} cluster_id=${index} cluster_name=${cluster_name}"
      print_terraform "addons/${addon}" \
                      "${cloud_provider}-${index}-${region}" \
                      "-var=cloud=${cloud_provider} -var=cluster_id=${index}" \
                      "outputs/terraform_outputs/terraform-${addon}-${cloud_provider}-${index}.json"

      cd "addons/${addon}"
      terraform workspace new ${cloud_provider}-${index}-${region} || true
      terraform workspace select ${cloud_provider}-${index}-${region}
      terraform init
      terraform apply ${TERRAFORM_APPLY_ARGS} -var-file="../../${JSON_TFVARS}" -var=cloud=${cloud_provider} -var=cluster_id=${index}
      terraform output ${TERRAFORM_OUTPUT_ARGS} | jq . > ../../outputs/terraform_outputs/terraform-${addon}-${cloud_provider}-${index}.json
      terraform workspace select default
      index=$((index+1))
      cd "../.."
    done < <(echo "${clusters}")
  done
}

function deploy_external_dns() {
  set -e
  local index=0

  # Process both mp_cluster (index 0) and cp_clusters (index 1...n)
  for cluster_type in mp_cluster cp_clusters; do
    if [ "${cluster_type}" == "mp_cluster" ]; then
      local clusters=$(jq -c ".${cluster_type}" ${JSON_TFVARS})
    else
      local clusters=$(jq -c ".${cluster_type}[]" ${JSON_TFVARS})
    fi
    if [ -z "${clusters}" ]; then continue; fi

    while read -r cluster; do
      local region=$(echo "${cluster}" | jq -r '.region')
      local cloud_provider=$(echo "${cluster}" | jq -r '.cloud_provider')
      local cluster_name=""
      local name_from_json=$(echo "${cluster}" | jq -r '.name')
      # [backwards compatibility] if name not set or empty, fall back to previous naming convention
      if [ -n "${name_from_json}" ] && [ "${name_from_json}" != "null" ]; then
        cluster_name="${cloud_provider}-${name_from_json}"
      else 
        cluster_name="${cloud_provider}-${name_prefix}-${region}-${index}"
      fi
      print_info "cloud=${cloud_provider} region=${region} cluster_id=${index} cluster_name=${cluster_name}"
      print_terraform "addons/${cloud_provider}/external-dns" \
                      "${cloud_provider}-${index}-${region}" \
                      "-var=cloud=${cloud_provider} -var=cluster_id=${index}" \
                      " "

      cd "addons/${cloud_provider}/external-dns"
      terraform workspace new ${cloud_provider}-${index}-${region} || true
      terraform workspace select ${cloud_provider}-${index}-${region}
      terraform init
      terraform apply ${TERRAFORM_APPLY_ARGS} -var-file="../../../${JSON_TFVARS}" -var=cloud=${cloud_provider} -var=cluster_id=${index}
      terraform workspace select default
      index=$((index+1))
      cd "../../.."
    done < <(echo "${clusters}")
  done
}

function destroy_external_dns() {
  set -e
  local index=0

  # Process both mp_cluster (index 0) and cp_clusters (index 1...n)
  for cluster_type in mp_cluster cp_clusters; do
    if [ "${cluster_type}" == "mp_cluster" ]; then
      local clusters=$(jq -c ".${cluster_type}" ${JSON_TFVARS})
    else
      local clusters=$(jq -c ".${cluster_type}[]" ${JSON_TFVARS})
    fi
    if [ -z "${clusters}" ]; then continue; fi

    while read -r cluster; do
      local region=$(echo "${cluster}" | jq -r '.region')
      local cloud_provider=$(echo "${cluster}" | jq -r '.cloud_provider')
      local cluster_name=""
      local name_from_json=$(echo "${cluster}" | jq -r '.name')
      # [backwards compatibility] if name not set or empty, fall back to previous naming convention
      if [ -n "${name_from_json}" ] && [ "${name_from_json}" != "null" ]; then
        cluster_name="${cloud_provider}-${name_from_json}"
      else 
        cluster_name="${cloud_provider}-${name_prefix}-${region}-${index}"
      fi
      print_info "cloud=${cloud_provider} region=${region} cluster_id=${index} cluster_name=${cluster_name}"
        
      cd "addons/${cloud_provider}/external-dns"
      terraform workspace new ${cloud_provider}-${index}-${region} || true
      terraform workspace select ${cloud_provider}-${index}-${region}
      terraform init
      terraform destroy ${TERRAFORM_APPLY_ARGS} -var-file="../../../${JSON_TFVARS}" -var=cloud=${cloud_provider} -var=cluster_id=$index
      terraform workspace select default

      index=$((index+1))
      cd "../../.."
    done < <(echo "${clusters}")
  done
}

function destroy_remote() {

  local cloud_provider=$(jq -r '.mp_cluster.cloud_provider' ${JSON_TFVARS})
  local fqdn=$(jq -r '.tsb.fqdn' ${JSON_TFVARS})
  local address=$(jq -r 'if .ingress_ip.value != "" then .ingress_ip.value else .ingress_hostname.value end' outputs/terraform_outputs/terraform-tsb-mp.json)

  cd "tsb/fqdn/$cloud_provider"
  terraform init
  terraform destroy ${TERRAFORM_APPLY_ARGS} -var-file="../../../${JSON_TFVARS}" -var=address=${address} -var=fqdn=${fqdn}
  rm -rf terraform.tfstate.d/
  rm -rf terraform.tfstate
  cd "../../.."
}

function destroy_k8s_clusters() {
  set -e
  local index=0
  local name_prefix=$(jq -r '.name_prefix' ${JSON_TFVARS})

  # Process both mp_cluster (index 0) and cp_clusters (index 1...n)
  for cluster_type in mp_cluster cp_clusters; do
    if [ "${cluster_type}" == "mp_cluster" ]; then
      local clusters=$(jq -c ".${cluster_type}" ${JSON_TFVARS})
    else
      local clusters=$(jq -c ".${cluster_type}[]" ${JSON_TFVARS})
    fi
    if [ -z "${clusters}" ]; then continue; fi

    while read -r cluster; do
      local region=$(echo "${cluster}" | jq -r '.region')
      local cloud_provider=$(echo "${cluster}" | jq -r '.cloud_provider')
      local cluster_name=""
      local name_from_json=$(echo "${cluster}" | jq -r '.name')
      # [backwards compatibility] if name not set or empty, fall back to previous naming convention
      if [ -n "${name_from_json}" ] && [ "${name_from_json}" != "null" ]; then
        cluster_name="${cloud_provider}-${name_from_json}"
      else 
        cluster_name="${cloud_provider}-${name_prefix}-${region}-${index}"
      fi
      print_info "cloud=${cloud_provider} region=${region} zones=${zones} cluster_id=${index} cluster_name=${cluster_name}"

      cd "infra/${cloud_provider}"
      if ! $(terraform workspace select ${cloud_provider}-${index}-${region}) ; then
        print_info "Workspace ${cloud_provider}-${index}-${region} no longer exist..."
        index=$((index+1))
        cd "../.."
        continue
      fi
      terraform destroy ${TERRAFORM_DESTROY_ARGS} -var-file="../../${JSON_TFVARS}" -var=${cloud_provider}_k8s_region=${region} -var=cluster_id=${index} -var=cluster_name=${cluster_name}
      terraform workspace select default
      terraform workspace delete ${TERRAFORM_WORKSPACE_ARGS} ${cloud_provider}-${index}-${region}

      index=$((index+1))
      cd "../.."
    done < <(echo "${clusters}")
  done
}


#
# Main execution
#
case "$1" in
  help)
    help
    ;;
  validate)
    print_stage "validate_json_structure"
    validate_json_structure
    ;;
  k8s_clusters)
    print_stage "deploy_k8s_clusters"
    deploy_k8s_clusters
    ;;
  k8s_auths)
    print_stage "deploy_k8s_auths"
    deploy_k8s_auths
    ;;
  tsb_mp)
    print_stage "deploy_tsb_mp"
    deploy_tsb_mp
    ;;
  tsb_cps)
    print_stage "deploy_tsb_cps"
    deploy_tsb_cps
    ;;
  fluxcd)
    print_stage "deploy_addon fluxcd"
    deploy_addon "fluxcd"
    ;;
  argocd)
    print_stage "deploy_addon argocd"
    deploy_addon "argocd"
    ;;
  tsb_monitoring)
    print_stage "deploy_addon tsb-monitoring"
    deploy_addon "tsb-monitoring"
    ;;
  external_dns)
    print_stage "deploy_external_dns"
    deploy_external_dns
    ;;
  destroy_external_dns)
    print_stage "destroy_external_dns"
    destroy_external_dns
    ;;
  destroy_remote)
    print_stage "destroy_remote"
    destroy_remote
    ;;
  destroy_k8s)
    print_stage "destroy_k8s_clusters"
    destroy_k8s_clusters
    ;;
  *)
    echo "Invalid option. Use 'help' to see available commands."
    ;;
esac