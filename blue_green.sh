#!/bin/bash

# This script can update a new version of a service running on Kubernetes.
# Prerequisite: Service (deployment and service) is currently running.

DEPLOYMENTNAME=$1-$3
SERVICE=$1
OLD_VERSION=$2
NEW_VERSION=$3
DEPLOYMENTFILE=$4
RAMPDOWN=$1-$2

echo -e "Pods:\n"
kubectl get pods
echo -e "\nDeploy new version..."
kubectl apply -f $DEPLOYMENTFILE
echo -e "\nWait until new version is ready..."
READY=$(kubectl get deploy $DEPLOYMENTNAME -o json | jq '.status.conditions[] | select(.reason == "MinimumReplicasAvailable") | .status' | tr -d '"')
while [[ "$READY" != "True" ]]; do
    READY=$(kubectl get deploy $DEPLOYMENTNAME -o json | jq '.status.conditions[] | select(.reason == "MinimumReplicasAvailable") | .status' | tr -d '"')
    sleep 5
done
echo "... new version is ready:"
kubectl get pods

echo -e "\nRelease..."
echo "- Update service with the new version..."
kubectl patch svc $SERVICE -p "{\"spec\":{\"selector\": {\"name\": \"${SERVICE}\", \"version\": \"${NEW_VERSION}\"}}}"
kubectl delete deployment $RAMPDOWN
echo -e "... Release finished.\n"
