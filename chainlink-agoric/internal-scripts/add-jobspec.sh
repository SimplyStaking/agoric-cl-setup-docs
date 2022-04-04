#!/bin/bash

source ./internal-scripts/common.sh

add_jobspec() {
  title "Adding Jobspec #$1 to Chainlink node..."

  CL_URL="http://localhost:6691"

  login_cl "$CL_URL"

  payload=$(cat $1 | jq -r '.')

  echo -n "Posting..."
  while true; do
    RESULT=$(curl -s -b ./tmp/cookiefile -d "$payload" -X POST -H 'Content-Type: application/json' "$CL_URL/v2/specs")
    JOBID=$(echo $RESULT | jq -r '.data.id')
    [[ "$JOBID" == null ]] || break
    echo -n .
    sleep 5
  done
  echo " done!"

  echo "Jobspec $JOBID has been added to Chainlink node"
  title "Done adding jobspec #$1"
}