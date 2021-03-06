#!/usr/bin/env bash

set -ex

if oc get namespace tekton-pipelines > /dev/null 2>&1; then
  exit 0
fi

KUBEVIRT_VERSION=$(curl -s https://github.com/kubevirt/kubevirt/releases/latest | grep -o "v[0-9]\.[0-9]*\.[0-9]*")
CDI_VERSION=$(curl -s https://github.com/kubevirt/containerized-data-importer/releases/latest | grep -o "v[0-9]\.[0-9]*\.[0-9]*")
COMMON_TEMPLATES_VERSION=$(curl -s https://github.com/kubevirt/common-templates/releases/latest | grep -o "v[0-9]\.[0-9]*\.[0-9]*")

# Deploy Tekton Pipelines
oc new-project tekton-pipelines
oc adm policy add-scc-to-user anyuid -z tekton-pipelines-controller
oc adm policy add-scc-to-user anyuid -z tekton-pipelines-webhook
oc apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.notags.yaml
oc project default

# Deploy Kubevirt
oc create -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml"

oc create -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml"

oc apply -f - <<EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: kubevirt-config
  namespace: kubevirt
data:
  feature-gates: "DataVolumes"
---
EOF

# Deploy Storage
oc create -f "https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-operator.yaml"

oc create -f "https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-cr.yaml"

# Deploy Common Templates
oc create -n openshift -f "https://github.com/kubevirt/common-templates/releases/download/${COMMON_TEMPLATES_VERSION}/common-templates-${COMMON_TEMPLATES_VERSION}.yaml"


# wait for tekton pipelines
oc rollout status -n tekton-pipelines deployment/tekton-pipelines-controller --timeout 10m
oc rollout status -n tekton-pipelines deployment/tekton-pipelines-webhook --timeout 10m

# Wait for kubevirt to be available
oc wait -n kubevirt kv kubevirt --for condition=Available --timeout 10m
oc rollout status -n cdi deployment/cdi-operator --timeout 10m
