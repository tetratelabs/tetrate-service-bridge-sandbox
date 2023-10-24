#!/usr/bin/env bash
#
# Helper script with shared helper functions

SUPPORTED_CLOUDS=("azure" "aws" "gcp")
DEFAULT_K8S_VERSION="1.27"

# Color values sorted as
#   - bold (<NAME>_B)
#   - marker-background (<NAME>_M)
#   - underline (<NAME>_U)
#   - normal (<NAME>)
#
# END is the terminator to skip back to default color
#

END="\033[0m"

# shellcheck disable=SC2034  # (unused vars)
{
  BLACK_B="\033[1;30m"
  BLACK_M="\033[40m"
  BLACK_U="\033[4;30m"
  BLACK="\033[0;30m"

  BLUE_B="\033[1;34m"
  BLUE_M="\033[44m"
  BLUE_U="\033[4;34m"
  BLUE="\033[0;34m"

  GRAY_B="\033[1;90m"
  GRAY_M="\033[100m"
  GRAY_U="\033[4;90m"
  GRAY="\033[0;90m"

  GREEN_B="\033[1;32m"
  GREEN_M="\033[42m"
  GREEN_U="\033[4;32m"
  GREEN="\033[0;32m"

  LIGHTBLUE_B="\033[1;36m"
  LIGHTBLUE_M="\033[46m"
  LIGHTBLUE_U="\033[4;36m"
  LIGHTBLUE="\033[0;36m"

  LIGHTGRAY_B="\033[1;97m"
  LIGHTGRAY_M="\033[107m"
  LIGHTGRAY_U="\033[4;97m"
  LIGHTGRAY="\033[0;97m"

  LIGHTGREEN_B="\033[1;92m"
  LIGHTGREEN_M="\033[102m"
  LIGHTGREEN_U="\033[4;92m"
  LIGHTGREEN="\033[0;92m"

  LIGHTPURPLE_B="\033[1;94m"
  LIGHTPURPLE_M="\033[104m"
  LIGHTPURPLE_U="\033[4;94m"
  LIGHTPURPLE="\033[0;94m"

  LIGHTRED_B="\033[1;91m"
  LIGHTRED_M="\033[101m"
  LIGHTRED_U="\033[4;91m"
  LIGHTRED="\033[0;91m"

  LIGHTYELLOW_B="\033[1;93m"
  LIGHTYELLOW_M="\033[103m"
  LIGHTYELLOW_U="\033[4;93m"
  LIGHTYELLOW="\033[0;93m"

  PURPLE_B="\033[1;35m"
  PURPLE_M="\033[45m"
  PURPLE_U="\033[4;35m"
  PURPLE="\033[0;35m"

  RED_B="\033[1;31m"
  RED_M="\033[41m"
  RED_U="\033[4;31m"
  RED="\033[0;31m"

  WHITE_B="\033[1;37m"
  WHITE_M="\033[47m"
  WHITE_U="\033[4;37m"
  WHITE="\033[0;37m"

  YELLOW_B="\033[1;33m"
  YELLOW_M="\033[43m"
  YELLOW_U="\033[4;33m"
  YELLOW="\033[0;33m"
}

# This function is used to print informational messages to the console.
# It displays the message in bold green color.
# 
# Parameters:
#   $1 - The informational message to be displayed.
#
# Usage: print_info "Your informational message here"
function print_info {
  echo -e "${GREEN_B}${1}${END}"
}

# This function is used to print warning messages to the console.
# It displays the message in bold yellow color.
# 
# Parameters:
#   $1 - The warning message to be displayed.
#
# Usage: print_warning "Your warning message here"
function print_warning {
  echo -e "${YELLOW_B}${1}${END}"
}

# This function is used to print error messages to the console.
# It displays the message in bold red color.
# 
# Parameters:
#   $1 - The error message to be displayed.
#
# Usage: print_error "Your error message here
function print_error {
  echo -e "${RED_B}${1}${END}"
}

# This function is used to print command messages to the console.
# It displays the message in bold light blue color.
# 
# Parameters:
#   $1 - The command message to be displayed.
#
# Usage: print_command "Your command message here"
function print_command {
  echo -e "${LIGHTBLUE_B}${1}${END}"
}

# This function is used to print stage messages to the console.
# It displays the message in bold blue color.
# 
# Parameters:
#   $1 - The command message to be displayed.
#
# Usage: print_stage "Your stage here"
function print_stage {
  echo -e "${BLUE_B}${1}${END}"
}

# This function is used to either execute a given command or print it to the console.
# The behavior is determined by the DRY_RUN flag. If DRY_RUN is set to true, the function
# will print the command without executing it. Otherwise, it will execute the command.
#
# Parameters:
#   $@ - The command and its arguments to be executed or printed.
#
# Usage:
#   run cd "directory/path"
#   run terraform apply "arguments"
function run() {
  if ${DRY_RUN}; then
    printf "%s\n" "$*"
  else
    eval "$@"
  fi
}

# This function retrieves the number of elements in a specified cloud provider's array
# from a tfvar.json file.
#
# Parameters:
#   $1 - The path to the tfvar.json file.
#   $2 - The cloud provider ("aws," "azure," or "gcp").
#
# Usage:
#   get_cluster_count "tfvar.json" "azure"
function get_cluster_count() {
  [[ -z "${1}" ]] && print_error "Please provide tfvar.json file as 1st argument" && return 1 || local json_file="${1}" ;
  [[ -z "${2}" ]] && print_error "Please provide cloud provider as 2nd argument" && return 1 || local cloud="${2}" ;
  if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${cloud} "* ]]; then print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'." ; return 1 ; fi

  jq --arg cloud "${cloud}" '.k8s_clusters[$cloud] | length' "${json_file}"
}

# This function retrieves the cluster config object from a tfvar.json file
# based on the specified cloud provider and index. It sets the 'name' property
# if it's not available in the cluster configuration.
#
# Parameters:
#   $1 - The path to the tfvar.json file.
#   $2 - The cloud provider ("aws," "azure," or "gcp").
#   $3 - The index of the nested array under the specified cloud.
#
# Usage:
#   get_cluster_config "tfvar.json" "azure" 0
function get_cluster_config() {
  [[ -z "${1}" ]] && print_error "Please provide tfvar.json file as 1st argument" && return 1 || local json_file="${1}" ;
  [[ -z "${2}" ]] && print_error "Please provide cloud provider as 2nd argument" && return 1 || local cloud="${2}" ;
  if ! [[ " ${SUPPORTED_CLOUDS[*]} " == *" ${cloud} "* ]]; then print_error "Invalid cloud provider. Must be one of '${SUPPORTED_CLOUDS[*]}'." ; return 1 ; fi
  [[ -z "${3}" ]] && print_error "Please provide index as 3rd argument" && return 1 || local index="${3}" ;

  local cluster=$(jq -r --arg cloud "${cloud}" --argjson index "${index}" '.k8s_clusters[$cloud][$index] + {cloud: $cloud, index: $index}' "${json_file}")
  local name_prefix=$(jq -r '.name_prefix' "${json_file}")
  local cluster_region=$(jq -r '.region' <<< "${cluster}")
  local cluster_version=$(jq -r '.version // ""' <<< "${cluster}")
  local cluster_name=$(jq -r '.name // ""' <<< "${cluster}")

  # Check of cluster name is set, if not fall back on previous behavior
  if [ -z "${cluster_name}" ]; then
    cluster_name="${cloud}-${name_prefix}-${cluster_region}-${index}"
    cluster=$(jq --arg name "${cluster_name}" '. + {name: $name}' <<< "${cluster}")
  fi

  # Check if cluster k8s version is set, if not default to DEFAULT_K8S_VERSION
  if [ -z "${cluster_version}" ]; then
    cluster=$(jq --arg version "${DEFAULT_K8S_VERSION}" '. + {version: $version}' <<< "${cluster}")
  fi

  # Set a unique terraform workspace in order to support multiple environments in parallel
  # We do support re-using cluster_name accross environments by including name_prefix (unique)
  local workspace_name="${cloud}-${name_prefix}-${cluster_region}-${index}"
  cluster=$(jq --arg workspace "${workspace_name}" '. + {workspace: $workspace}' <<< "${cluster}")

  # Return resulting augmented cluster object
  echo $(jq --sort-keys . <<< ${cluster})
}

# This function retrieves the index of the cluster with "management_plane": true
# from a tfvar.json file, regardless of the cloud provider.
#
# Parameters:
#   $1 - The path to the tfvar.json file.
#
# Usage:
#   get_mp_cluster_index "tfvar.json"
function get_mp_cluster_index() {
  [[ -z "${1}" ]] && print_error "Please provide tfvar.json file as 1st argument" && return 1 || local json_file="${1}" ;

  jq -r '.k8s_clusters // {} | to_entries[] | .key as $cloud | .value | to_entries[] | select(.value.tetrate.management_plane == true) | .key' "${json_file}"
}

# This function retrieves the cluster config object with "management_plane": true
# from a tfvar.json file, regardless of the cloud provider. It sets the 'name' property
# if it's not available in the cluster configuration.
#
# Parameters:
#   $1 - The path to the tfvar.json file.
#
# Usage:
#   get_mp_cluster_config "tfvar.json"
function get_mp_cluster_config() {
  [[ -z "${1}" ]] && print_error "Please provide tfvar.json file as 1st argument" && return 1 || local json_file="${1}" ;

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

  # Check if cluster k8s version is set, if not default to DEFAULT_K8S_VERSION
  if [ -z "${cluster_version}" ]; then
    cluster=$(jq --arg version "${DEFAULT_K8S_VERSION}" '. + {version: $version}' <<< "${cluster}")
  fi

  # Set a unique terraform workspace in order to support multiple environments in parallel
  # We do support re-using cluster_name accross environments by including name_prefix (unique)
  local workspace_name="${cloud}-${name_prefix}-${cluster_region}-${index}"
  cluster=$(jq --arg workspace "${workspace_name}" '. + {workspace: $workspace}' <<< "${cluster}")

  # Return resulting augmented cluster object
  echo $(jq --sort-keys . <<< ${cluster})
}

# This function retrieves the workspace information from a given cluster configuration.
#
# Parameters:
#   $1 - The cluster configuration in JSON format.
#
# Usage:
#   workspace=$(get_cluster_workspace "$cluster_config")
#
function get_cluster_workspace() {
  [[ -z "${1}" ]] && print_error "Please provide cluster config as 1st argument" && return 1 || local cluster="${1}" ;
  echo $(jq -r '.workspace' <<< "${cluster}")
}

# This function retrieves the cloud provider information from a given cluster configuration.
#
# Parameters:
#   $1 - The cluster configuration in JSON format.
#
# Usage:
#   cloud_provider=$(get_cluster_cloud "$cluster_config")
#
function get_cluster_cloud() {
  [[ -z "${1}" ]] && print_error "Please provide cluster config as 1st argument" && return 1 || local cluster="${1}" ;
  echo $(jq -r '.cloud' <<< "${cluster}")
}

# This function checks if the given cluster configuration is for a management plane.
#
# Parameters:
#   $1 - The cluster configuration in JSON format.
#
# Usage:
#   if is_cluster_mp "$cluster_config"; then
#     echo "This is a management plane cluster."
#   fi
function is_cluster_mp() {
  [[ -z "${1}" ]] && print_error "Please provide cluster config as 1st argument" && return 1 || local cluster="${1}" ;
  echo $(jq -r '.tetrate.management_plane // false' <<< "${cluster}")
}

# This function checks if the given cluster configuration is for a control plane.
#
# Parameters:
#   $1 - The cluster configuration in JSON format.
#
# Usage:
#   if is_cluster_cp "$cluster_config"; then
#     echo "This is a control plane cluster."
#   fi
function is_cluster_cp() {
  [[ -z "${1}" ]] && print_error "Please provide cluster config as 1st argument" && return 1 || local cluster="${1}" ;
  echo $(jq -r '.tetrate.control_plane // false' <<< "${cluster}")
}

# This function checks if a specific addon is enabled in the cluster configuration.
# It safely handles cases where the addons section might be missing, or the specific
# addon is not present in the configuration. In such cases, it defaults to returning "false".
#
# Parameters:
#   $1 - The cluster configuration as a JSON string.
#   $2 - The name of the addon to check.
#
# Usage:
#   is_addon_enabled "<cluster_config>" "<addon_name>"
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
# Parameters:
#   $1 - The cluster configuration as a JSON string.
#   $2 - The name of the addon to retrieve the configuration for.
#
# Usage:
#   get_cluster_addon_config "<cluster_config>" "<addon_name>"
function get_cluster_addon_config() {
  [[ -z "${1}" ]] && print_error "Please provide cluster config as 1st argument" && return 1 || local cluster="${1}" ;
  [[ -z "${2}" ]] && print_error "Please provide addon name as 2nd argument" && return 1 || local addon_name="${2}" ;

  if [[ "$(is_cluster_addon_enabled "${cluster}" "${addon_name}")" != "true" ]]; then
    echo '{ "enabled": false }'
    return 0
  fi

  echo $(jq --sort-keys -r --arg addon "$addon_name" '.addons[$addon]' <<< "${cluster}")
}
