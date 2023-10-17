#!/usr/bin/env bash
#
# Helper script to destroy and cleanup the environment.

BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export BASE_DIR

# shellcheck source=/dev/null
source "${BASE_DIR}/helpers.sh"
# shellcheck source=/dev/null
source "${BASE_DIR}/variables.sh"

ACTION=${1}

# Validate input values.
SUPPORTED_ACTIONS=("help" "destroy_tfstate" "destroy_tfcache" "destroy_outputs")
if ! [[ " ${SUPPORTED_ACTIONS[*]} " == *" ${ACTION} "* ]]; then
  print_error "Invalid action '${ACTION}'. Must be one of '${SUPPORTED_ACTIONS[*]}'."
  exit 1
fi

# This function provides help information for the script.
function help() {
  echo "Usage: $0 <command> [options]"
  echo "Commands:"
  echo "  help              Display this help message."
  echo "  destroy_tfstate   Destroy terraform tfstate."
  echo "  destroy_tfcache   Destroy terraform tfcache."
  echo "  destroy_outputs   Destroy terraform output artifacts."
}

# This function destroys terraform tfstate.
#
# Usage: destroy_tfstate
function destroy_tfstate() {
  set -e
  print_info "Going to destroy terraform tfstate"
  run_or_print "find . -name *tfstate* -exec rm -rf {} +"
  print_info "Finished destroying terraform tfstate"
}

# This function destroys terraform tfcache.
#
# Usage: destroy_tfcache
function destroy_tfcache() {
  set -e
  print_info "Going to destroy terraform tfcache"
  run_or_print "find . -name .terraform -exec rm -rf {} +"
  run_or_print "find . -name .terraform.lock.hcl -delete"
  print_info "Finished destroying terraform tfcache"
}

# This function destroys terraform output artifacts.
#
# Usage: destroy_outputs
function destroy_outputs() {
  set -e
  print_info "Going to destroy terraform output artifacts"
	run_or_print "rm -f outputs/*-kubeconfig.sh outputs/*-jumpbox.sh outputs/*-kubeconfig outputs/*.jwk outputs/*.pem outputs/*-cleanup.sh"
	run_or_print "rm -f outputs/terraform_outputs/*.json"
  print_info "Finished destroying terraform output artifacts"
}


#
# Main execution
#
case "${ACTION}" in
  help)
    help
    ;;
  destroy_tfstate)
    print_stage "Going to destroy terraform tfstate"
    destroy_tfstate
    ;;
  destroy_tfcache)
    print_stage "Going to destroy terraform tfcache"
    destroy_tfcache
    ;;
  destroy_outputs)
    print_stage "Going to destroy terraform output artifacts"
    destroy_outputs
    ;;
  *)
    print_error "Invalid option. Use 'help' to see available commands."
    help
    ;;
esac
