# building

## docker images

build and tag docker images

    export IMG=ghcr.io/platform-mesh/resource-broker:v0.1.0
    export IMG_KCP=ghcr.io/platform-mesh/resource-broker-kcp:v0.1.0
    export IMG_OPERATOR=ghcr.io/platform-mesh/resource-broker-operator:v0.1.0

    make docker-build docker-build-kcp docker-build-operator

    kind load docker-image --name platform-mesh "$IMG_KCP" "$IMG_OPERATOR"

    docker push $IMG
    docker push $IMG_KCP
    docker push $IMG_OPERATOR

## build the manifests for a full rbo deployment

    ( cd config/operator/default && kustomize edit set image operator=${IMG_OPERATOR}   )

    ( cd config/operator/default && kustomize build > ../../../operator-deployment.yaml   )

    echo "---" >> operator-deployment.yaml

    k create namespace resource-broker-system --dry-run=client -o=yaml >> operator-deployment.yaml

## create local CTF

    ocm add cv --force --create --file ctf-archive ./component-constructor.yaml

## push CTF to remote

    ocm transfer ctf --overwrite ctf-archive ghcr.io/ntnn/resource-broker

## publishing done

the packages will be private by default and not associated with the fork.

both the docker images and the ocm CVs are available in github:

    https://github.com/ntnn?tab=packages&repo_name=resource-broker

# deploying

## setup

create a kind cluster

    kind create cluster --name ocm

    kind export kubeconfig --name ocm --kubeconfig kubeconfig.yaml

    kset kubeconfig.yaml

install flux as a deployer for ocm

    kubectl apply -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml

    k rollout status deployment -n flux-system

install cert-manager for ocm

    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.19.2/cert-manager.yaml

    kubectl rollout status deployment -n cert-manager

Wait for both to be ready:

    kubectl rollout status deployment -n cert-manager && k rollout status deployment -n flux-system

install ocm-k8s-toolkit

    helm install ocm-k8s-toolkit oci://ghcr.io/open-component-model/charts/ocm-k8s-toolkit \
        --namespace ocm-k8s-toolkit-system \
        --create-namespace

<!-- install a cluster-issuer and cert for ocm -->
<!--  -->
<!--     k apply -f https://raw.githubusercontent.com/open-component-model/ocm-controller/refs/heads/main/hack/cluster_issuer.yaml -->
<!--  -->
<!-- copy the certificate into the ocm-system namespace -->
<!--  -->
<!--     k create namespace ocm-system -->
<!--  -->
<!--     k patch -n cert-manager certificate mpas-bootstrap-certificate --type json -p '[{"op":"replace","path":"/metadata/namespace","value":"ocm-system"}]' --dry-run=client -o yaml \ -->
<!--         | k apply -f- -->
<!--  -->
<!--     k delete -n cert-manager certificate mpas-bootstrap-certificate -->
<!--  -->
<!-- install ocm crds -->
<!--  -->
<!--     k create namespace ocm-k8s-toolkit-system -->
<!--  -->
<!--     kubectl apply --namespace ocm-k8s-toolkit-system -k "https://github.com/open-component-model/open-component-model/kubernetes/controller/config/default?ref=main" -->
<!--  -->
<!-- install ocm-controller -->
<!--  -->
<!--     k apply -k 'https://github.com/open-component-model/ocm-controller/deploy/flux/ocm-controller?ref=main' -->
<!--  -->
<!-- wait for everything to be ready -->
<!--  -->
<!--     k rollout status deployment -n ocm-system -->

## deploying the broker operator

    k apply -f install-operator.yaml

    k apply -f install-broker.yaml
