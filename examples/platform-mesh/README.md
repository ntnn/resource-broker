# platform-mesh

This example deploys resource-broker as a provider in the [Platform Mesh](https://platform-mesh.io/).

Loosely following the instructions in the provider quickstart: https://github.com/platform-mesh/provider-quickstart/tree/init

> [!NOTE]
> At present the guide is only targeting the local setup of Platform Mesh.
> The guide will be updated in the future to include other deployment options.

## Preparation

Set two environment variables - one for the Platform Mesh instance and
one for the compute cluster:

```bash
cp ../platform-mesh-helm-charts/.secret/kcp/admin.kubeconfig kcp-admin.kubeconfig
export PM_KUBECONFIG="$(realpath kcp-admin.kubeconfig)"
kind export kubeconfig --name platform-mesh --kubeconfig compute.kubeconfig
export COMPUTE_KUBECONFIG="$(realpath compute.kubeconfig)"
```

The `PM_KUBECONFIG` will be created when we set up the Platform Mesh
organisation and account later.

### Platform Mesh

This setup needs a running Platform Mesh instance. The easiest way to
get one is to deploy the [local setup](https://github.com/platform-mesh/helm-charts/tree/main/local-setup).

### Build and load images

Build the resource-broker-operator and resource-broker-kcp images and
load them into the kind cluster:

```bash ci
export IMG_KCP=resource-broker-kcp:platform-mesh
export IMG_OPERATOR=resource-broker-operator:platform-mesh

make docker-build-kcp docker-build-operator

make kind-load-kcp kind-load-operator KIND_CLUSTER=platform-mesh
```

### Deploy operator

Deploy the operator and it's resources into the kind cluster:

```bash ci
make deploy-operator KUBECONFIG="$COMPUTE_KUBECONFIG"
```

## Provider setup in Platform Mesh

### Workspace

> [!NOTE]
> Why do users see all organisations? Should that be the case?

Create layout:

```bash
KUBECONFIG="$PM_KUBECONFIG" kubectl ws :root
KUBECONFIG="$PM_KUBECONFIG" kubectl create-workspace --type root:providers --enter providers --ignore-existing
KUBECONFIG="$PM_KUBECONFIG" kubectl create-workspace --type root:provider --enter resource-broker --ignore-existing
```

> [!NOTE]
> Users shouldn't have different passwords for different organisations,
> that is very confusing.

TODO: check if it wouldn't be enough to create a "normal" account workspace with the root:provider type


> [!WARNING]
> The following is how I think this should work. Above is the current
> setup.

Create an organisation and an account in Platform Mesh. For the local
setup in this example we are using the organisation
`resource-broker-org` and the account `resource-broker`.

Download the kubeconfig for the account and set that as the
`PM_KUBECONFIG`.

```bash
export PM_KUBECONFIG=path/to/pm.kubeconfig
```

<!--
export PM_KUBECONFIG="$(realpath pm.kubeconfig)"

export PM_KUBECONFIG="$(realpath pm-provider.kubeconfig)"


KUBECONFIG="$PM_KUBECONFIG" kubectl ws :root
KUBECONFIG="$PM_KUBECONFIG" kubectl create-workspace --enter providers
KUBECONFIG="$PM_KUBECONFIG" kubectl create-workspace --enter resource-broker
-->

### Resources

Setup the APIResourceSchema. For this example we'll be using the `Certificate` example.

Create the APIResourcheSchema for Certificate and AcceptAPI:

```bash
kubectl kcp crd snapshot --prefix current --output yaml \
    -f ./config/example/crd/example.platform-mesh.io_certificates.yaml \
    | KUBECONFIG="$PM_KUBECONFIG" kubectl apply -f -
kubectl kcp crd snapshot --prefix current --output yaml \
    -f ./config/broker/crd/broker.platform-mesh.io_acceptapis.yaml \
    | KUBECONFIG="$PM_KUBECONFIG" kubectl apply -f -
```

And then kustomize the APIExports, RBAC and Platform Mesh resources:

```bash
KUBECONFIG="$PM_KUBECONFIG" kubectl apply -k ./examples/platform-mesh/example.platform-mesh.io
```
