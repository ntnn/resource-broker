#!/usr/bin/env sh

declare -a kubeconfigs
kubeconfigs=(
    ./kubeconfigs/internalca.kubeconfig
    ./kubeconfigs/externalca.kubeconfig
    ./kubeconfigs/platform.kubeconfig
    ./kubeconfigs/workspaces/externalca.kubeconfig
    ./kubeconfigs/workspaces/externalca.vw.kubeconfig
    ./kubeconfigs/workspaces/internalca.kubeconfig
    ./kubeconfigs/workspaces/internalca.vw.kubeconfig
    ./kubeconfigs/workspaces/consumer.vw.kubeconfig
    ./kubeconfigs/workspaces/consumer.kubeconfig
    ./kubeconfigs/platform.kubeconfig
)

IFS=,

../mermaid-kube-live/bin/mermaid-kube-live serve \
    --config ./mkl.yaml \
    --diagram ./mkl.mermaid \
    --kubeconfig "${kubeconfigs[*]}"
