#!/bin/bash
set -e

NAMESPACE=${NAMESPACE:-stackgen}
echo "Checking pod statuses in namespace: $NAMESPACE"

# Get all pods in the namespace
PODS=$(kubectl get pods -n $NAMESPACE --no-headers -o custom-columns=":metadata.name")

# Check the status of each pod
for POD in $PODS; do
  STATUS=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.phase}')
  echo "Pod: $POD, Status: $STATUS"
  if [ "$STATUS" != "Running" ]; then
    echo "Pod $POD is not running. Test failed."
    exit 1
  fi
done

echo "All pods are running!"
exit 0
