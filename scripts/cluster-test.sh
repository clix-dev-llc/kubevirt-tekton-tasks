#!/usr/bin/env bash

set -e

RET_CODE=0

SCOPE="${SCOPE:-cluster}"
DEBUG="${DEBUG:-false}"
STORAGE_CLASS="${STORAGE_CLASS:-}"
NUM_NODES="${NUM_NODES:-2}"
DEPLOY_NAMESPACE="${DEPLOY_NAMESPACE:-$(oc project --short)}"
ARTIFACT_DIR="${ARTIFACT_DIR:=dist}"
ARTIFACT_DIR="$(readlink -m "${ARTIFACT_DIR}")"
TEST_OUT="${ARTIFACT_DIR}/test.out"


rm -rf "${TEST_OUT}" "${ARTIFACT_DIR}/"junit*
mkdir -p "${ARTIFACT_DIR}"

if [[ "$SCOPE" == "cluster" ]]; then
    export TEST_NAMESPACE="${TEST_NAMESPACE:-e2e-tests-$(shuf -i10000-99999 -n1)}"
else
    export TEST_NAMESPACE="${TEST_NAMESPACE:-$DEPLOY_NAMESPACE}"
fi

oc get namespaces -o name | grep -Eq "^namespace/$TEST_NAMESPACE$" || oc new-project "$TEST_NAMESPACE" > /dev/null
oc get namespaces -o name | grep -Eq "^namespace/$DEPLOY_NAMESPACE$" || oc new-project "$DEPLOY_NAMESPACE" > /dev/null

oc project "$DEPLOY_NAMESPACE"

pushd modules/tests || exit
  rm -rf dist
  set +e
  set -o pipefail

  ginkgo -r -p --randomizeAllSpecs --randomizeSuites --failOnPending --trace --race --nodes="${NUM_NODES}" -- \
    --deploy-namespace="${DEPLOY_NAMESPACE}" \
    --test-namespace="${TEST_NAMESPACE}" \
    --kubeconfig-path="${KUBECONFIG}" \
    --scope="${SCOPE}" \
    --storage-class="${STORAGE_CLASS}" \
    --debug="${DEBUG}" | tee "${TEST_OUT}"

  RET_CODE="${PIPESTATUS[0]}"
  set -e

  cp dist/junit* "${ARTIFACT_DIR}"
popd

exit "${RET_CODE}"
