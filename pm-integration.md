# PM integration

Start a pm setup:

    task local-setup:cached:iterate

Export the kubeconfig for the kind cluster:

    kind export kubeconfig --name platform-mesh --kubeconfig kind.kubeconfig

And copy the kubeconfig for the kcp control plane:

    cp ../platform-mesh-helm-charts/.secret/kcp/admin.kubeconfig kcp-admin.kubeconfig

## install resource-broker-operator

Install the resource-broker-operator:

    ( cd config/operator/default && kustomize edit set image operator=ghcr.io/platform-mesh/resource-broker-operator:v0.1.0 )

    KUBECONFIG=kind.kubeconfig kubectl create namespace resource-broker-system

    KUBECONFIG=kind.kubeconfig kubectl apply -k config/operator/default

reset the kustomization.yaml to avoid committing the image override:

    git checkout -- config/operator/default/kustomization.yaml

## prepare kcp

Create a workspace for the resource broker, this will just live at `:root:resource-broker` for now:

    KUBECONFIG=kcp-admin.kubeconfig kubectl create-workspace resource-broker

    KUBECONFIG=kcp-admin.kubeconfig kubectl ws :root:resource-broker

### brokered APIs

First setup the APIs to broker and the APIExport for it.
Create the APIResourceSchema for the Certificate:

    kubectl kcp crd snapshot --prefix current -f ./config/example/crd/example.platform-mesh.io_certificates.yaml --output=yaml \
        | KUBECONFIG=kcp-admin.kubeconfig kubectl apply -f -

And for AcceptAPI:

    kubectl kcp crd snapshot --prefix current -f ./config/broker/crd/broker.platform-mesh.io_acceptapis.yaml --output=yaml \
        | KUBECONFIG=kcp-admin.kubeconfig kubectl apply -f -

And create the APIExports:

    KUBECONFIG=kcp-admin.kubeconfig kubectl apply -f pm-apiexport.yaml

### broker setup

Install the resource-broker migration CRDs into the workspace, they are
not needed but rb expects them:

    KUBECONFIG=kcp-admin.kubeconfig kubectl apply -f config/broker/crd/broker.platform-mesh.io_migrations.yaml

    KUBECONFIG=kcp-admin.kubeconfig kubectl apply -f config/broker/crd/broker.platform-mesh.io_migrationconfigurations.yaml

Install the resource-broker namespace and RBAC:

    KUBECONFIG=kcp-admin.kubeconfig kubectl create namespace resource-broker-system

    ( cd config/broker/rbac && kustomize edit set namespace resource-broker-system )

    KUBECONFIG=kcp-admin.kubeconfig kubectl apply --namespace resource-broker-system -k config/broker/rbac

    git checkout -- config/broker/rbac

And RBAC for kcp primitives:

    KUBECONFIG=kcp-admin.kubeconfig kubectl create clusterrole resource-broker-kcp \
        --resource=apiexports,apibindings,apiexportendpointslices --verb='*'

    KUBECONFIG=kcp-admin.kubeconfig kubectl create clusterrolebinding resource-broker-kcp \
        --clusterrole=resource-broker-kcp \
        --user=system:serviceaccount:resource-broker-system:resource-broker

And a kubeconfig for the operator:

    KUBECONFIG=kcp-rb.kubeconfig kubectl config set-cluster kcp \
        --server="https://frontproxy-front-proxy.platform-mesh-system.svc.cluster.local:6443/clusters/root:resource-broker" \
        --insecure-skip-tls-verify=true

    KUBECONFIG=kcp-rb.kubeconfig kubectl config set-credentials service-account \
        --token="$(KUBECONFIG=kcp-admin.kubeconfig kubectl -n resource-broker-system create token resource-broker --duration=271560h)"

    KUBECONFIG=kcp-rb.kubeconfig kubectl config set-context kcp --cluster=kcp --user=service-account

    KUBECONFIG=kcp-rb.kubeconfig kubectl config use-context kcp

Quick smokecheck for the kubeconfig:

    KUBECONFIG=kcp-rb.kubeconfig kubectl get apiexports

## deploy resource-broker

A clean namespace:

    KUBECONFIG=kind.kubeconfig kubectl create namespace resource-broker \
        --dry-run=client -o yaml \
        | kubectl apply -f -

Push the built kubeconfig as a secret:

    KUBECONFIG=kind.kubeconfig kubectl create secret generic kcp-rb-kubeconfig \
        --namespace resource-broker \
        --from-file=kubeconfig=kcp-rb.kubeconfig \
        --dry-run=client -o yaml \
        | kubectl apply -f -

And the service account and things:

    ( cd config/broker/rbac && kustomize edit set namespace resource-broker )

    KUBECONFIG=kind.kubeconfig kubectl apply -k config/broker/rbac

    git checkout -- config/broker/rbac

And deploy the broker:

    KUBECONFIG=kind.kubeconfig kubectl apply -f ./broker.yaml
