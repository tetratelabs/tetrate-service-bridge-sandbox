
#!/usr/bin/env bash
#
# Helper script to convert old tfvars schema to newest version
#

if [ "$#" -ne 2 ]; then
    echo "Usage: ${0} <input_file> <output_file>"
    exit 1
fi
input_json="${1}"
output_json="${2}"

if [ ! -f "${input_json}" ]; then
    echo "Error: Input file '${input_json}' does not exist."
    exit 1
fi

echo "Going to convert ${input_json} ..."
jq -n --argjson input "$(cat ${input_json})" \
'{
  cp_clusters: (
    ($input.aws_k8s_regions | to_entries | map({
      cloud_provider: "aws",
      name: ("demo" + (.key + 1 | tostring)),
      region: .value,
      version: "1.24"
    })) +
    ($input.azure_k8s_regions | to_entries | map({
      cloud_provider: "azure",
      name: ("demo" + (.key + 1 + ($input.aws_k8s_regions | length) | tostring)),
      region: .value,
      version: "1.24"
    })) +
    ($input.gcp_k8s_regions | to_entries | map({
      cloud_provider: "gcp",
      name: ("demo" + (.key + 1 + ($input.aws_k8s_regions | length) + ($input.azure_k8s_regions | length) | tostring)),
      region: .value,
      version: "1.24"
    }))
  ),
  dns_provider: $input.dns_provider,
  mp_cluster: {
    cloud_provider: $input.tsb_mp.cloud,
    name: "mp-demo",
    region: 
      (if $input.tsb_mp.cloud == "aws" then 
        $input.aws_k8s_regions[$input.tsb_mp.cluster_id] 
      elif $input.tsb_mp.cloud == "azure" then 
        $input.azure_k8s_regions[$input.tsb_mp.cluster_id] 
      else 
        $input.gcp_k8s_regions[$input.tsb_mp.cluster_id] 
      end),
    tier1: true,
    version: "1.24"
  },
  name_prefix: $input.name_prefix,
  tetrate: {
    owner: $input.tetrate_owner,
    team: $input.tetrate_team
  },
  tsb: {
    fqdn: $input.tsb_fqdn,
    image_sync_apikey: $input.tsb_image_sync_apikey,
    image_sync_username: $input.tsb_image_sync_username,
    organisation: $input.tsb_org,
    password: $input.tsb_password,
    version: $input.tsb_version
  }
}' > ${output_json}

echo "Conversion complete. Check the ${output_json} file."
