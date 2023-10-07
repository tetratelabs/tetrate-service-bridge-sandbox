
#!/usr/bin/env bash
#
# Helper script to avoid makefile escaping and other shenanigans
#
export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

JSON_TFVARS="terraform.tfvars.json"
TERRAFORM_APPLY_ARGS="-compact-warnings -auto-approve"
TERRAFORM_DESTROY_ARGS="-compact-warnings -auto-approve"
TERRAFORM_WORKSPACE_ARGS="-force"
TERRAFORM_OUTPUT_ARGS="-json"

# Enable debug
# set -o xtrace

function validate_json_structure() {    
  if jq -e '.cp_clusters[] | select(.cloud_provider and .name and .region and .version and .zones)' "$JSON_TFVARS" > /dev/null && \
     jq -e '.dns_provider | select(. == "aws" or . == "gcp" or . == "azure")' "$JSON_TFVARS" > /dev/null && \
     jq -e '.mp_cluster | select(.cloud_provider and .name and .region and .version and .zones)' "$JSON_TFVARS" > /dev/null && \
     jq -e '.name_prefix' "$JSON_TFVARS" > /dev/null && \
     jq -e '.tsb | select(.fqdn and .image_sync_apikey and .image_sync_username and .organisation and .password and .version)' "$JSON_TFVARS" > /dev/null && \
     jq -e '.cp_clusters[] | select(.cloud_provider == "aws" or .cloud_provider == "gcp" or .cloud_provider == "azure")' "$JSON_TFVARS" > /dev/null && \
     jq -e '.mp_cluster | select(.cloud_provider == "aws" or .cloud_provider == "gcp" or .cloud_provider == "azure")' "$JSON_TFVARS" > /dev/null; then
    echo "JSON structure is valid."
  else
    echo "JSON structure is invalid."
    return 1
  fi
}

function deploy_k8s_clusters() {
  set -e
  local index=0
  local name_prefix=$(jq -r '.name_prefix' ${JSON_TFVARS})

  # Process both cp_clusters and mp_cluster
  for cluster_type in cp_clusters mp_cluster; do
    if [ "${cluster_type}" == "mp_cluster" ]; then
      local clusters=$(jq -c ".${cluster_type}" ${JSON_TFVARS})
    else
      local clusters=$(jq -c ".${cluster_type}[]" ${JSON_TFVARS})
    fi
    if [ -z "${clusters}" ]; then continue; fi

    echo "${clusters}" | while read -r cluster; do
      local region=$(echo "${cluster}" | jq -r '.region')
      local cloud_provider=$(echo "${cluster}" | jq -r '.cloud_provider')
      local cluster_name=""
      local name_from_json=$(echo "${cluster}" | jq -r '.name')
      # [backwards compatibility] if name not set or empty, fall back to previous naming convention
      if [ -n "${name_from_json}" ] && [ "${name_from_json}" != "null" ]; then
        cluster_name="aks-${name_from_json}"
      else 
        cluster_name="aks-${name_prefix}-${region}-${index}"
      fi
      # [todo] zones is not implemented yet
      local zones=$(echo "${cluster}" | jq -r '.zones | join(",")')
      echo "cloud=${cloud_provider} region=${region} zones=${zones} cluster_id=${index} cluster_name=${cluster_name}"
      continue

      cd "infra/${cloud_provider}"
      terraform workspace new ${cloud_provider}-${index}-${region} || true
      terraform workspace select ${cloud_provider}-${index}-${region}
      terraform init
      terraform apply ${TERRAFORM_APPLY_ARGS} -target module.${cloud_provider}_base -var-file="../../${JSON_TFVARS}" -var=${cloud_provider}_k8s_region=${region} -var=cluster_name=${cluster_name} -var=cluster_id=${index}
      terraform apply ${TERRAFORM_APPLY_ARGS} -var-file="../../${JSON_TFVARS}" -var=${cloud_provider}_k8s_region=${region} -var=cluster_name=${cluster_name} -var=cluster_id=${index}
      terraform output ${TERRAFORM_OUTPUT_ARGS} | jq . > ../../outputs/terraform_outputs/terraform-${cloud_provider}-${cluster_name}-${index}.json
      terraform workspace select default

      index=$((index+1))
      cd "../.."
    done
  done
}

function deploy_k8s_auths() {
  set -e
  local cloud_provider=${1}
  local index=0
  local name_prefix=$(jq -r '.name_prefix' ${JSON_TFVARS})

  # Process both cp_clusters and mp_cluster
  for cluster_type in cp_clusters mp_cluster; do
    if [ "${cluster_type}" == "mp_cluster" ]; then
      local clusters=$(jq -c ".${cluster_type}" ${JSON_TFVARS})
    else
      local clusters=$(jq -c ".${cluster_type}[]" ${JSON_TFVARS})
    fi
    if [ -z "${clusters}" ]; then continue; fi

    echo "${clusters}" | while read -r cluster; do
      local region=$(echo "${cluster}" | jq -r '.region')
      local cloud_provider=$(echo "${cluster}" | jq -r '.cloud_provider')
      local cluster_name=""
      local name_from_json=$(echo "${cluster}" | jq -r '.name')
      # [backwards compatibility] if name not set or empty, fall back to previous naming convention
      if [ -n "${name_from_json}" ] && [ "${name_from_json}" != "null" ]; then
        cluster_name="aks-${name_from_json}"
      else 
        cluster_name="aks-${name_prefix}-${region}-${index}"
      fi
      echo "cloud=${cloud_provider} region=${region} cluster_id=${index} cluster_name=${cluster_name}"
      continue

      cd "infra/${cloud_provider}/k8s_auth"
      terraform workspace new "${cloud_provider}-${index}-${region}" || true
      terraform workspace select "${cloud_provider}-${index}-${region}"
      terraform init
      terraform apply -refresh=false ${TERRAFORM_APPLY_ARGS} -var-file="../../../${JSON_TFVARS}" -var="${cloud_provider}_k8s_region=${region}" -var=cluster_id=${index}      
      terraform workspace select default

      index=$((index+1))
      cd "../../.."
    done
  done
}

function deploy_tsb_mp() {
  set -e
  local cloud_provider=$(jq -r '.mp_cluster.cloud_provider' ${JSON_TFVARS})
  local region=$(jq -r '.mp_cluster.region' ${JSON_TFVARS})
  local cluster_name=$(jq -r '.mp_cluster.name' ${JSON_TFVARS})
  local dns_provider=$(jq -r '.dns_provider' ${JSON_TFVARS})
  if [ "${dns_provider}" == "null" ] || [ -z "${dns_provider}" ] ; then
    # TODO: review this logic
    dns_provider=$(jq -r '.tsb.fqdn' ${JSON_TFVARS} | cut -d"." -f2 | sed 's/sandbox/gcp/g')
  fi
  echo "cloud=${cloud_provider} region=${region} cluster_id=0 cluster_name=${cluster_name}"
  return

  cd "tsb/mp"
  terraform workspace select default
  terraform init
  terraform apply ${TERRAFORM_APPLY_ARGS} -target=module.cert-manager -target=module.es -target="data.terraform_remote_state.infra" -var-file="../../${JSON_TFVARS}"
  terraform apply ${TERRAFORM_APPLY_ARGS} -target=module.tsb_mp.kubectl_manifest.manifests_certs -target="data.terraform_remote_state.infra" -var-file="../../${JSON_TFVARS}"
  terraform apply ${TERRAFORM_APPLY_ARGS} -var-file="../../${JSON_TFVARS}"
  terraform output ${TERRAFORM_OUTPUT_ARGS} | jq . > ../../outputs/terraform_outputs/terraform-tsb-mp.json

  local fqdn=$(jq -r '.tsb.fqdn' ../../${JSON_TFVARS})
  local address=$(jq -r "if .ingress_ip.value != \"\" then .ingress_ip.value else .ingress_hostname.value end" ../../outputs/terraform_outputs/terraform-tsb-mp.json)

  terraform -chdir=../fqdn/${dns_provider} init
  terraform -chdir=../fqdn/${dns_provider} apply ${TERRAFORM_APPLY_ARGS} -var-file="../../../${JSON_TFVARS}" -var=address=${address} -var=fqdn=${fqdn}
  terraform workspace select default

  cd "../.."
}

function deploy_tsb_cps() {
    set -e
    local index=0
    clusters=$(jq -c '.cp_clusters[]' ${JSON_TFVARS})

    for cluster in $clusters; do
      cloud_provider=$(echo $cluster | jq -r '.cloud_provider')
      cluster_name=$(echo $cluster | jq -r '.name')
      region=$(echo $cluster | jq -r '.region')
      version=$(echo $cluster | jq -r '.version')
      echo "cloud=${cloud_provider} region=${region} cluster_id=${index} cluster_name=${cluster_name}"
      continue

      cd "tsb/cp"
      terraform workspace new ${cloud_provider}-${index}-${region} || true
      terraform workspace select ${cloud_provider}-${index}-${region}
      terraform init
      terraform apply ${TERRAFORM_APPLY_ARGS} -var-file="../../${JSON_TFVARS}" -var=cloud=${cloud_provider} -var=cluster_id=${index}
      terraform workspace select default

      index=$((index+1))
      cd "../../.."
    done
}

function deploy_addon() {
  set -e
  local index=0
  local addon=${1}

  # Process both cp_clusters and mp_cluster
  for cluster_type in cp_clusters mp_cluster; do
    if [ "${cluster_type}" == "mp_cluster" ]; then
      local clusters=$(jq -c ".${cluster_type}" ${JSON_TFVARS})
    else
      local clusters=$(jq -c ".${cluster_type}[]" ${JSON_TFVARS})
    fi
    if [ -z "${clusters}" ]; then continue; fi

    echo "${clusters}" | while read -r cluster; do
      local region=$(echo "${cluster}" | jq -r '.region')
      local cloud_provider=$(echo "${cluster}" | jq -r '.cloud_provider')
      local cluster_name=""
      local name_from_json=$(echo "${cluster}" | jq -r '.name')
      # [backwards compatibility] if name not set or empty, fall back to previous naming convention
      if [ -n "${name_from_json}" ] && [ "${name_from_json}" != "null" ]; then
        cluster_name="aks-${name_from_json}"
      else 
        cluster_name="aks-${name_prefix}-${region}-${index}"
      fi
      echo "cloud=${cloud_provider} region=${region} cluster_id=${index} cluster_name=${cluster_name}"
      continue
        
      cd "addons/${addon}"
      terraform workspace new ${cloud_provider}-${index}-${region} || true
      terraform workspace select ${cloud_provider}-${index}-${region}
      terraform init
      terraform apply ${TERRAFORM_APPLY_ARGS} -var-file="../../${JSON_TFVARS}" -var=cloud=${cloud_provider} -var=cluster_id=${index}
      terraform output ${TERRAFORM_OUTPUT_ARGS} | jq . > ../../outputs/terraform_outputs/terraform-${addon}-${cloud_provider}-${index}.json
      terraform workspace select default
      index=$((index+1))
      cd "../.."
    done
  done
}

function deploy_external_dns() {
  set -e
  local index=0

  # Process both cp_clusters and mp_cluster
  for cluster_type in cp_clusters mp_cluster; do
    if [ "${cluster_type}" == "mp_cluster" ]; then
      local clusters=$(jq -c ".${cluster_type}" ${JSON_TFVARS})
    else
      local clusters=$(jq -c ".${cluster_type}[]" ${JSON_TFVARS})
    fi
    if [ -z "${clusters}" ]; then continue; fi

    echo "${clusters}" | while read -r cluster; do
      local region=$(echo "${cluster}" | jq -r '.region')
      local cloud_provider=$(echo "${cluster}" | jq -r '.cloud_provider')
      local cluster_name=""
      local name_from_json=$(echo "${cluster}" | jq -r '.name')
      # [backwards compatibility] if name not set or empty, fall back to previous naming convention
      if [ -n "${name_from_json}" ] && [ "${name_from_json}" != "null" ]; then
        cluster_name="aks-${name_from_json}"
      else 
        cluster_name="aks-${name_prefix}-${region}-${index}"
      fi
      echo "cloud=${cloud_provider} region=${region} cluster_id=${index} cluster_name=${cluster_name}"
      continue
        
      cd "addons/${cloud_provider}/external-dns"
      terraform workspace new ${cloud_provider}-${index}-${region} || true
      terraform workspace select ${cloud_provider}-${index}-${region}
      terraform init
      terraform apply ${TERRAFORM_APPLY_ARGS} -var-file="../../../${JSON_TFVARS}" -var=cloud=${cloud_provider} -var=cluster_id=${index}
      terraform workspace select default
      index=$((index+1))
      cd "../../.."
    done
  done
}

function destroy_external_dns() {
  set -e
  local index=0

  # Process both cp_clusters and mp_cluster
  for cluster_type in cp_clusters mp_cluster; do
    if [ "${cluster_type}" == "mp_cluster" ]; then
      local clusters=$(jq -c ".${cluster_type}" ${JSON_TFVARS})
    else
      local clusters=$(jq -c ".${cluster_type}[]" ${JSON_TFVARS})
    fi
    if [ -z "${clusters}" ]; then continue; fi

    echo "${clusters}" | while read -r cluster; do
      local region=$(echo "${cluster}" | jq -r '.region')
      local cloud_provider=$(echo "${cluster}" | jq -r '.cloud_provider')
      local cluster_name=""
      local name_from_json=$(echo "${cluster}" | jq -r '.name')
      # [backwards compatibility] if name not set or empty, fall back to previous naming convention
      if [ -n "${name_from_json}" ] && [ "${name_from_json}" != "null" ]; then
        cluster_name="aks-${name_from_json}"
      else 
        cluster_name="aks-${name_prefix}-${region}-${index}"
      fi
      echo "cloud=${cloud_provider} region=${region} cluster_id=${index} cluster_name=${cluster_name}"
      continue
        
      cd "addons/${cloud_provider}/external-dns"
      terraform workspace new ${cloud_provider}-${index}-${region} || true
      terraform workspace select ${cloud_provider}-${index}-${region}
      terraform init
      terraform destroy ${TERRAFORM_APPLY_ARGS} -var-file="../../../${JSON_TFVARS}" -var=cloud=${cloud_provider} -var=cluster_id=$index
      terraform workspace select default

      index=$((index+1))
      cd "../../.."
    done
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

  # Process both cp_clusters and mp_cluster
  for cluster_type in cp_clusters mp_cluster; do
    if [ "${cluster_type}" == "mp_cluster" ]; then
      local clusters=$(jq -c ".${cluster_type}" ${JSON_TFVARS})
    else
      local clusters=$(jq -c ".${cluster_type}[]" ${JSON_TFVARS})
    fi
    if [ -z "${clusters}" ]; then continue; fi

    echo "${clusters}" | while read -r cluster; do
      local region=$(echo "${cluster}" | jq -r '.region')
      local cloud_provider=$(echo "${cluster}" | jq -r '.cloud_provider')
      local cluster_name=""
      local name_from_json=$(echo "${cluster}" | jq -r '.name')
      # [backwards compatibility] if name not set or empty, fall back to previous naming convention
      if [ -n "${name_from_json}" ] && [ "${name_from_json}" != "null" ]; then
        cluster_name="aks-${name_from_json}"
      else 
        cluster_name="aks-${name_prefix}-${region}-${index}"
      fi
      echo "cloud=${cloud_provider} region=${region} zones=${zones} cluster_id=${index} cluster_name=${cluster_name}"
      continue

      cd "infra/${cloud_provider}"
      terraform workspace select ${cloud_provider}-${index}-${region}
      cluster_name=$(terraform output cluster_name | jq . -r)
      terraform destroy ${TERRAFORM_DESTROY_ARGS} -var-file="../../${JSON_TFVARS}" -var=$*_k8s_region=${region} -var=cluster_id=${index} -var=cluster_name=${cluster_name}
      terraform workspace select default

      index=$((index+1))
      cd "../.."
    done
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
    validate_json_structure
    ;;
  k8s_clusters)
    deploy_k8s_clusters
    ;;
  k8s_auths)
    deploy_k8s_auths
    ;;
  tsb_mp)
    deploy_tsb_mp
    ;;
  tsb_cps)
    deploy_tsb_cps
    ;;
  fluxcd)
    deploy_addon "fluxcd"
    ;;
  argocd)
    deploy_addon "argocd"
    ;;
  tsb_monitoring)
    deploy_addon "tsb-monitoring"
    ;;
  external_dns)
    deploy_external_dns
    ;;
  destroy_external_dns)
    destroy_external_dns
    ;;
  destroy_remote)
    destroy_remote
    ;;
  destroy_k8s)
    destroy_k8s_clusters
    ;;
  *)
    echo "Invalid option. Use 'help' to see available commands."
    ;;
esac