#!/usr/bin/env bash
#
# Helper script with shared helper functions
BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export BASE_DIR

source "${BASE_DIR}/variables.sh"
source "${BASE_DIR}/prints.sh"

# This function is used to either execute a given command or print it to the console.
# The behavior is determined by the DRY_RUN flag. If DRY_RUN is set to true, the function
# will print the command without executing it. Otherwise, it will execute the command.
#
function run() {
  if ${DRY_RUN:-false}; then
    printf "%s\n" "$*"
  else
    eval "$@"
  fi
}

# This function retrieves the number of elements in a specified cloud provider's array
# from a terraform.tfvars.json file.
#
function get_cluster_count() {
  [[ -z "${1}" ]] && print_error "Please provide terraform.tfvars.json file as 1st argument" && return 1 || local json_file="${1}" ;
  [[ -z "${2}" ]] && print_error "Please provide cloud provider as 2nd argument" && return 1 || local cloud="${2}" ;

  if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${cloud} "* ]]; then 
    print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'." ; 
    return 1 ; 
  fi

  jq --arg cloud "${cloud}" '.k8s_clusters[$cloud] | length' "${json_file}"
}

# This function retrieves the cluster config object from a terraform.tfvars.json file
# based on the specified cloud provider and index. It sets the 'name' property
# if it's not available in the cluster configuration.
#
function get_cluster_config() {
  [[ -z "${1}" ]] && print_error "Please provide terraform.tfvars.json file as 1st argument" && return 1 || local json_file="${1}" ;
  [[ -z "${2}" ]] && print_error "Please provide cloud provider as 2nd argument" && return 1 || local cloud="${2}" ;
  if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${cloud} "* ]]; then print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'." ; return 1 ; fi
  [[ -z "${3}" ]] && print_error "Please provide index as 3rd argument" && return 1 || local index="${3}" ;

  local cluster=$(jq -r --arg cloud "${cloud}" --argjson index "${index}" '.k8s_clusters[$cloud][$index] + {cloud: $cloud, index: $index}' "${json_file}")
  local name_prefix=$(jq -r '.name_prefix' "${json_file}")
  local cluster_region=$(jq -r '.region' <<< "${cluster}")
  local cluster_version=$(jq -r '.version // ""' <<< "${cluster}")
  local cluster_name=$(jq -r '.name // ""' <<< "${cluster}")

  # Check of cluster name is set, generate one if not using the format cloud - name_prefix - region - index
  if [ -z "${cluster_name}" ]; then
    cluster_name="${cloud}-${name_prefix}-${cluster_region}-${index}"
    cluster=$(jq --arg name "${cluster_name}" '. + {name: $name}' <<< "${cluster}")
  fi

  # Set a unique terraform workspace in order to support multiple environments in parallel
  # We do support re-using cluster_name across environments by including name_prefix (unique)
  local workspace_name="${cloud}-${name_prefix}-${cluster_region}-${index}"
  cluster=$(jq --arg workspace "${workspace_name}" '. + {workspace: $workspace}' <<< "${cluster}")

  # Return resulting augmented cluster object
  echo $(jq -c --sort-keys . <<< ${cluster})
}

# This function retrieves the index of the cluster with "management_plane": true
# from a terraform.tfvars.json file, regardless of the cloud provider.
#
function get_mp_cluster_index() {
  [[ -z "${1}" ]] && print_error "Please provide terraform.tfvars.json file as 1st argument" && return 1 || local json_file="${1}" ;

  jq -r '.k8s_clusters // {} | to_entries[] | .key as $cloud | .value | to_entries[] | select(.value.tetrate.management_plane == true) | .key' "${json_file}"
}

# This function retrieves the cluster config object with "management_plane": true
# from a terraform.tfvars.json file, regardless of the cloud provider. 
#
function get_mp_cluster_config() {
  [[ -z "${1}" ]] && print_error "Please provide terraform.tfvars.json file as 1st argument" && return 1 || local json_file="${1}" ;

  local index=$(get_mp_cluster_index "${1}")
  [[ -z "${index}" ]] && print_error "No cloud with management plane found." && return 1

  local cluster=$(jq -r --argjson index "${index}" 'if .k8s_clusters then .k8s_clusters else {} end | to_entries[] | .key as $cloud | .value[] | select(.tetrate.management_plane == true) |
      { 
        "cloud": $cloud, 
        "index": $index 
      } + .' "${1}")

  local name_prefix=$(jq -r '.name_prefix' "${json_file}")
  local cloud=$(jq -r '.cloud // ""' <<< "${cluster}")
  local cluster_region=$(jq -r '.region' <<< "${cluster}")
  local cluster_version=$(jq -r '.version // ""' <<< "${cluster}")
  local cluster_name=$(jq -r '.name // ""' <<< "${cluster}")

  # Check of cluster name is set, if not fall back on previous behavior
  if [ -z "${cluster_name}" ]; then
    cluster_name="${cloud}-${name_prefix}-${cluster_region}-${index}"
    cluster=$(jq --arg name "${cluster_name}" '. + {name: $name}' <<< "${cluster}")
  fi

  # Set a unique terraform workspace in order to support multiple environments in parallel
  # We do support re-using cluster_name accross environments by including name_prefix (unique)
  local workspace_name="${cloud}-${name_prefix}-${cluster_region}-${index}"
  cluster=$(jq --arg workspace "${workspace_name}" '. + {workspace: $workspace}' <<< "${cluster}")

  # Return resulting augmented cluster object
  echo $(jq -c --sort-keys . <<< ${cluster})
}

# This function retrieves the workspace information from a given cluster configuration.
#
function get_cluster_workspace() {
  [[ -z "${1}" ]] && print_error "Please provide cluster config as 1st argument" && return 1 || local cluster="${1}" ;
  echo $(jq -r '.workspace' <<< "${cluster}")
}

# This function retrieves the cloud provider information from a given cluster configuration.
#
function get_cluster_cloud() {
  [[ -z "${1}" ]] && print_error "Please provide cluster config as 1st argument" && return 1 || local cluster="${1}" ;
  echo $(jq -r '.cloud' <<< "${cluster}")
}

# This function checks if the given cluster configuration is for a management plane.
#
function is_cluster_mp() {
  [[ -z "${1}" ]] && print_error "Please provide cluster config as 1st argument" && return 1 || local cluster="${1}" ;
  echo $(jq -r '.tetrate.management_plane // false' <<< "${cluster}")
}

# This function checks if the given cluster configuration is for a control plane.
#
function is_cluster_cp() {
  [[ -z "${1}" ]] && print_error "Please provide cluster config as 1st argument" && return 1 || local cluster="${1}" ;
  echo $(jq -r '.tetrate.control_plane // false' <<< "${cluster}")
}

# This function checks if a specific addon is enabled in the cluster configuration.
# It safely handles cases where the addons section might be missing, or the specific
# addon is not present in the configuration. In such cases, it defaults to returning "false".
#
function is_cluster_addon_enabled() {
  [[ -z "${1}" ]] && print_error "Please provide cluster config as 1st argument" && return 1 || local cluster="${1}" ;
  [[ -z "${2}" ]] && print_error "Please provide addon name as 2nd argument" && return 1 || local addon_name="${2}" ;

  if ! $(jq -e '.addons' <<< "${cluster}" &> /dev/null); then
    echo "false"
    return 0
  fi

  local addon_status
  addon_status=$(jq -r --arg addon "$addon_name" '.addons[$addon].enabled // "false"' <<< "${cluster}")
  echo "${addon_status}"
}

# This function retrieves the configuration of a specific addon from the cluster configuration.
# It first checks if the addon is enabled. If the addon is not enabled or not present,
# the function will return a JSON object with "enabled" set to false.
# If the addon is enabled, it will print the JSON configuration of the addon.
#
function get_cluster_addon_config() {
  [[ -z "${1}" ]] && print_error "Please provide cluster config as 1st argument" && return 1 || local cluster="${1}" ;
  [[ -z "${2}" ]] && print_error "Please provide addon name as 2nd argument" && return 1 || local addon_name="${2}" ;

  if [[ "$(is_cluster_addon_enabled "${cluster}" "${addon_name}")" != "true" ]]; then
    echo '{ "enabled": false }'
    return 0
  fi

  echo $(jq -c --sort-keys -r --arg addon "$addon_name" '.addons[$addon]' <<< "${cluster}")
}