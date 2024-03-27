# Pulumi Typescript GitOps Bridge

### Prerequisites
- [Get a Free Pulumi Cloud account](https://app.pulumi.com/)
- [Install pulumi CLI](https://www.pulumi.com/docs/clouds/aws/get-started/begin/#install-pulumi)
- [Install Nodejs](https://nodejs.org/en/download/)

### Install Pulumi SDK
```shell
npm install
```

### Setup Credentials
- Add an Environment Variable for `PULUMI_ACCESS_TOKEN` or use `pulumi login`
- Add an Environment Variable for `GITHUB_TOKEN` in your deployment env (local, Github Actions, AWS Code Pipeline, etc;)

### How to Start Your Hub Cluster:
1. Review `Pulumi.hub.yaml` and update configuration values as you need - You will want to update Stack Files with configuration for Github Repo/Org, as well as AWS Account ID, CIDRs, etc;
1. Add any extra resources you may need in your given environment
1. Run Pulumi Up for the Hub Cluster's Stack `pulumi up --stack hub`
1. Wait for the Resources to create like VPC, EKS Cluster, and IAM permissions
1. Set environment variable `ARGO_IAM_ROLE_ARN` before running next step `export ARGO_IAM_ROLE_ARN=$(pulumi stack output -s hub -j | jq .outputs.argoRoleArn -r)`
1. Run `./bootstrap.sh` to install ArgoCD on Hub cluster
1. Setup kubectl cli `aws eks --region us-east-1 update-kubeconfig --name hub-cluster --alias hub-cluster`
1. Access ArgoCD UI:
    ```shell
    echo "Username: admin"
    echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" --context hub-cluster | base64 -d)"
    echo "Access https://localhost:8080"
    kubectl -n argocd port-forward svc/argocd-server 8080:443 --context hub-cluster
    ```

### How to Add Spoke Clusters:
1. Review `Pulumi.dev.yaml` and add any extra resources you may need in your given environment
1. Run Pulumi Up for the Spoke Cluster's Stack `pulumi up --stack dev`
1. Wait for the Resources to create like VPC, EKS Cluster, and IAM permissions
1. Apply the Secret resource that was added to the GitOps Repository
1. Setup kubectl cli `aws eks --region us-east-1 update-kubeconfig --name dev-cluster --alias dev-cluster`
1. Repeat for next cluster like `prod` `pulumi up --stack prod`

### Productionizing your Implementation

* Add Authentication for ArgoCD to be able to grab from your Organization's private repository
* Add ApplicationSets to your configuration by looking at the GitOps Bridge Control Plane Template for resources you need
* Create an ArgoCD Application that manages deployment of your Cluster Secret
* Move your EKS Cluster to be a private access endpoint