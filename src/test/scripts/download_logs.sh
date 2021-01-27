#!/usr/bin/env bash

set -x

source $1

RELEASE_PREFIX=$(echo "${RELEASE_PREFIX}" | tr '[:upper:]' '[:lower:]')
PRODUCT_RELEASE_NAME=$RELEASE_PREFIX-$PRODUCT_NAME

mkdir -p "$LOG_DOWNLOAD_DIR"

getPodLogs() {
    local releaseName=$1

    local podNames=$(kubectl -n "${TARGET_NAMESPACE}" get pods --selector app.kubernetes.io/instance="$releaseName" --output=jsonpath={.items..metadata.name})

    for podName in $podNames ; do
      echo Downloading logs from $podName...
      kubectl -n "${TARGET_NAMESPACE}" describe pod "$podName" > "$LOG_DOWNLOAD_DIR/$podName.yaml"
      local containers=$(kubectl -n "${TARGET_NAMESPACE}" get pod "$podName" -o 'jsonpath={.spec.containers[*].name}')
      for container in $containers; do
        kubectl -n "${TARGET_NAMESPACE}" logs --container="$container" "$podName" > "$LOG_DOWNLOAD_DIR/${podName}--${container}.log"
      done
    done
}

getIngresses() {
    local releaseName=$1

    local ingressNames=$(kubectl -n "${TARGET_NAMESPACE}" get ingress --selector app.kubernetes.io/instance="$releaseName" --output=jsonpath={.items..metadata.name})

    for ingressName in $ingressNames; do
      echo Describing ingress $ingressName...
      kubectl -n "${TARGET_NAMESPACE}" describe ingress "$ingressName" > "$LOG_DOWNLOAD_DIR/$ingressName-ingressName.yaml"
    done
}

getPodLogs "$PRODUCT_RELEASE_NAME"
getPodLogs "$RELEASE_PREFIX-pgsql"

getIngresses "$PRODUCT_RELEASE_NAME"

kubectl get events -n "${TARGET_NAMESPACE}" --sort-by=.metadata.creationTimestamp > "$LOG_DOWNLOAD_DIR/events.txt"

exit 0
