#!/usr/bin/env bash
#
# Helper script to describe the environment.
#
BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export BASE_DIR

source "${BASE_DIR}/helpers.sh"

ACTION=${1}

# Validate input values.
#
SUPPORTED_ACTIONS=("help" "all" "infra" "tetrate" "addons")
if ! [[ " ${SUPPORTED_ACTIONS[*]} " == *" ${ACTION} "* ]]; then
  print_error "Invalid action '${ACTION}'. Must be one of '${SUPPORTED_ACTIONS[*]}'."
  exit 1
fi

# This function provides help information for the script.
#
function help() {
  echo "Usage: $0 <command> [options]"
  echo "Commands:"
  echo "  help              Display this help message."
  echo "  all               Describe the setup."
  echo "  infra             Describe the infra setup."
  echo "  tetrate           Describe the tetrate setup."
  echo "  addons            Describe the addons setup."
  
}

# This function describes infrastructure details in a table-like format.
#
function describe_infra() {
  set -e
  print_info "Infrastructure details:"

  # Function to print cluster information in a table-like format
  print_cluster_info() {
      local platform=$1
      local clusters=$2
      local cluster_count=$(echo $clusters | jq length)

      echo "Found $cluster_count Kubernetes clusters in $platform."
      echo "------------------------------------------------------------------------------------------------"
      printf "%-20s | %-10s | %-20s | %-20s | %-15s\n" "Cluster Name" "Region" "Control Plane" "Management Plane" "ArgoCD Enabled"
      echo "------------------------------------------------------------------------------------------------"

      for i in $(seq 0 $(($cluster_count - 1))); do
          cluster_name=$(echo $clusters | jq -r ".[$i].name")
          region=$(echo $clusters | jq -r ".[$i].region")
          control_plane=$(echo $clusters | jq -r ".[$i].tetrate.control_plane")
          management_plane=$(echo $clusters | jq -r ".[$i].tetrate.management_plane")
          argocd_enabled=$(echo $clusters | jq -r ".[$i].addons.argocd.enabled")

          printf "%-20s | %-10s | %-20s | %-20s | %-15s\n" "$cluster_name" "$region" "$control_plane" "$management_plane" "$argocd_enabled"
      done

      echo ""
  }

  TFVARS=$(cat ${TFVARS_JSON})

  # Extract and print AWS clusters info
  AWS_CLUSTERS=$(echo $TFVARS | jq '.k8s_clusters.aws')
  print_cluster_info "AWS" "$AWS_CLUSTERS"

  # Extract and print Azure clusters info
  AZURE_CLUSTERS=$(echo $TFVARS | jq '.k8s_clusters.azure')
  print_cluster_info "Azure" "$AZURE_CLUSTERS"

  # Extract and print GCP clusters info
  GCP_CLUSTERS=$(echo $TFVARS | jq '.k8s_clusters.gcp')
  print_cluster_info "GCP" "$GCP_CLUSTERS"
}

function describe_tetrate() {
  set -e
  print_info "Tetrate details:"

  TFVARS=$(cat ${TFVARS_JSON})
  TETRATE_CONFIG=$(echo $TFVARS | jq '.tetrate')

  # Display Tetrate configuration in a table-like format
  echo "Tetrate Configuration:"
  echo "--------------------------------------"
  printf "%-20s | %s\n" "FQDN" "$(echo $TETRATE_CONFIG | jq -r '.fqdn')"
  printf "%-20s | %s\n" "Image Sync API Key" "$(echo $TETRATE_CONFIG | jq -r '.image_sync_apikey')"
  printf "%-20s | %s\n" "Image Sync Username" "$(echo $TETRATE_CONFIG | jq -r '.image_sync_username')"
  printf "%-20s | %s\n" "Organization" "$(echo $TETRATE_CONFIG | jq -r '.organization')"
  printf "%-20s | %s\n" "Password" "$(echo $TETRATE_CONFIG | jq -r '.password')"
  printf "%-20s | %s\n" "Version" "$(echo $TETRATE_CONFIG | jq -r '.version')"
  echo "--------------------------------------"
  echo ""
}

function describe_addons() {
  set -e
  print_info "Addons details:"
  # Addons description logic goes here
}



# Main execution
#
case "${ACTION}" in
  help)
    help
    ;;
  all)
    describe_infra
    describe_tetrate
    describe_addons
    ;;
  infra)
    describe_infra
    ;;
  tetrate)
    describe_tetrate
    ;;
  addons)
    describe_addons
    ;;
  *)
    print_error "Invalid option. Use 'help' to see available commands."
    help
    ;;
esac
