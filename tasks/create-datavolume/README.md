# Create DataVolume Task

This task creates a DataVolume with oc client.

## `create-datavolume`

### Installation

Install the Task

```bash
kubectl apply -f https://raw.githubusercontent.com/suomiy/kubevirt-tekton-tasks/master/tasks/create-datavolume/manifests/create-datavolume.yaml
```

Install one of the following rbac permissions to the active namespace
  - Namespace scoped DataVolume creation
    ```bash
    kubectl apply -f https://raw.githubusercontent.com/suomiy/kubevirt-tekton-tasks/master/tasks/create-datavolume/manifests/create-datavolume-namespace-rbac.yaml
    ```
  - Cluster scoped DataVolume creation
    ```bash
    # Replace MY_NAMESPACE with the target namespace
    wget -qO - https://raw.githubusercontent.com/suomiy/kubevirt-tekton-tasks/master/tasks/create-datavolume/manifests/create-datavolume-cluster-rbac.yaml | sed "s/TARGET_NAMESPACE/MY_NAMESPACE/" | kubectl apply -f -
    ```

### Parameters

- **manifest**: YAML manifest of a DataVolume resource to be created.
- **waitForSuccess**: `true`/`false` flag to require waititing for Ready condition of DataVolume.

### Results

- **name**: The name of DataVolume that was created.
- **namespace**: The namespace of DataVolume that was created.

### Usage

Please see [examples](examples)