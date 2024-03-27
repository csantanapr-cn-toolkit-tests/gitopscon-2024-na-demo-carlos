#!/bin/bash
set -ueo pipefail

export AWS_PROFILE=default

# Add EKS cluster to kubeconfig
aws eks --region us-east-1 update-kubeconfig --name hub-cluster --alias hub-cluster

# Install ArgoCD
kubectl create namespace argocd --context hub-cluster || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --context hub-cluster

kubectl annotate serviceaccount argocd-server argocd-application-controller \
    eks.amazonaws.com/role-arn=$ARGO_IAM_ROLE_ARN --namespace=argocd --context hub-cluster

kubectl rollout restart deployment argocd-server -n argocd --context hub-cluster
kubectl rollout restart sts argocd-application-controller -n argocd --context hub-cluster

kubectl create secret generic private-repo-creds -n argocd --context hub-cluster \
    --from-literal=username=REPLACE_USERNAME \
    --from-literal=password=$GITHUB_TOKEN \
    --from-literal=type=git \
    --from-literal=url=https://github.com/csantanapr/gitopscon-2024-na-demo-carlos \
    --dry-run=client -o yaml | \
    sed "s/namespace: argocd/namespace: argocd\n  labels:\n    argocd.argoproj.io\/secret-type: repository/" | \
    kubectl apply -f -

kubectl apply -f "../gitops/clusters/hub-cluster.yaml" --context hub-cluster
kubectl apply -f "../gitops/bootstrap/bootstrap-app.yaml" --context hub-cluster

# Echo command to port forward ArgoCD and get admin password
echo "To port forward ArgoCD run: kubectl -n argocd port-forward svc/argocd-server 8080:443 --context hub-cluster &"
echo "Password can be retrieved by running: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" --context hub-cluster | base64 -d"
