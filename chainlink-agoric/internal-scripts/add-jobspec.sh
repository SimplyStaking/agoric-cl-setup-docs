#!/bin/bash

source ./internal-scripts/common.sh

add_jobspec() {
  title "Adding Jobspec #$1 to Chainlink node..."

  CL_URL="http://localhost:6691"

  login_cl "$CL_URL"

  jq -Rs  '{toml: .}' $1 > tmpjob
  echo -n "Posting..."
  while true; do
    RESULT=$(curl -s -b ./tmp/cookiefile -d @tmpjob -X POST -H 'Content-Type: application/json' "$CL_URL/v2/jobs")
    JOBID=$(echo $RESULT | jq -r '.data.attributes.externalJobID')
    [[ "$JOBID" == null ]] || break
    echo -n .
    sleep 5
  done
  echo " done!"

  echo "Jobspec $JOBID has been added to Chainlink node"
  title "Done adding jobspec #$1"
}