
#!/bin/sh

export PROJECT=$1

# Get a list of all managed zones in the project
ZONES=$(gcloud dns managed-zones list --project="$PROJECT" --format="value(name)")

# Loop over each managed zone and delete all its DNS records and the zone itself
for ZONE in $ZONES; do
  # List all the DNS records in the zone and extract their names and types
  RECORDS=$(gcloud dns record-sets list --zone="$ZONE" --project="$PROJECT" --format="value(name,type)")

  # Delete each DNS record in the zone
  while IFS= read -r RECORD; do
    NAME=$(echo "$RECORD" | awk '{print $1}')
    TYPE=$(echo "$RECORD" | awk '{print $2}')
    echo "Deleting $TYPE record $NAME in zone $ZONE"
    gcloud dns record-sets delete "$NAME" --type="$TYPE" --zone="$ZONE" --project="$PROJECT" --quiet
  done <<< "$RECORDS"

  # Delete the zone
  echo "Deleting zone $ZONE"
  gcloud dns managed-zones delete "$ZONE" --project="$PROJECT" --quiet
done