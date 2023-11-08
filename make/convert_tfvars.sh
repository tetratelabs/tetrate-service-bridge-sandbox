#!/bin/bash
# This script converts the older tfvars format to the new one. 

# Ensure we have a filename
if [ $# -eq 0 ]; then
  echo "No arguments provided. Please provide the input JSON file."
  exit 1
fi

# Ensure jq is installed
if ! type "jq" > /dev/null; then
  echo "jq is not installed. Please install it to run this script."
  exit 1
fi

# Filename is the first argument
filename="$1"

# Check if the new format is detected
if jq -e '.k8s_clusters' "$filename" &>/dev/null; then
  echo "The input file is already in the new format. Conversion is not needed."
  exit 0
fi

# Parse the cloud and cluster id where the management plane should be set
mp_cloud=$(jq -r '.tsb_mp.cloud' "$filename")
mp_cluster_id=$(jq -r '.tsb_mp.cluster_id' "$filename")

# Initialize the management plane set flag to false
mp_set=false

# Parse tags
owner=$(jq -r '.tetrate_owner' "$filename")
team=$(jq -r '.tetrate_team' "$filename")

# Function to generate clusters
generate_clusters() {
  local cloud="$1"
  local regions_var="${cloud}_k8s_regions"
  local regions=$(jq -c ".${regions_var}[]" "$filename")
  local clusters_output=""
  for region in $regions; do
    clusters_output+=$(cat <<-END
      {
        "region": $region,
        "tetrate": {
          "control_plane": true
END
    )

    if [ "$mp_cloud" == "$cloud" -a "$mp_cluster_id" == "0" -a "$mp_set" == "false" ]; then
      clusters_output+=",\"management_plane\": true"
      mp_set=true
    fi

    clusters_output+="
        }
      },"
  done
  # Remove the last comma
  echo "${clusters_output%,}"
}

# Collect the output in a variable
output=$(cat <<-END
{
  "k8s_clusters": {
    "aws": [$(generate_clusters "aws")],
    "azure": [$(generate_clusters "azure")],
    "gcp": [$(generate_clusters "gcp")]
  },
  "tags": {
    "tetrate_owner": "$owner",
    "tetrate_team": "$team"
  },
  "name_prefix": "$(jq -r '.name_prefix' "$filename")",
  "tetrate": {
    "fqdn": "$(jq -r '.tsb_fqdn' "$filename")",
    "image_sync_apikey": "$(jq -r '.tsb_image_sync_apikey' "$filename")",
    "image_sync_username": "$(jq -r '.tsb_image_sync_username' "$filename")",
    "organization": "$(jq -r '.tsb_org' "$filename")",
    "password": "$(jq -r '.tsb_password' "$filename")",
    "version": "$(jq -r '.tsb_version' "$filename")"
  }
}
END
)

# Ask user for confirmation before overwriting
read -p "The older tfvars format is detected. Are you sure you want to overwrite $filename? This action cannot be undone. It is recommended to review the configuration once again before moving forward (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Format the output with jq and overwrite the file
    echo "$output" | jq '.' > "$filename"
    echo "The file $filename has been updated to the new format."
    jq '.' "$filename"
    read -p "Proceed with the environment standup (y/n) " -n 1 -r
    if [[ $REPLY =~ ^[Nn]$ ]]
      then
          exit 1
      fi
else
    echo "File overwrite canceled."
fi

# Prompt the user to update the target file
echo "Please review and update the target file as necessary."
