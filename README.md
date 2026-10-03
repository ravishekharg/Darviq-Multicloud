# Darviq Multicloud

[![validate](https://github.com/ravishekharg/Darviq-Multicloud/actions/workflows/validate.yml/badge.svg)](https://github.com/ravishekharg/Darviq-Multicloud/actions/workflows/validate.yml)

One application, deployed the same way to **Amazon EKS**, **Azure AKS** and **Google GKE**.
Terraform builds a production-shaped Kubernetes cluster on each cloud; a shared Kustomize base
deploys the app, and a thin overlay per cloud holds only what genuinely differs.

Built by [Darviq Systems](https://darviq.com).

## What's in it

```
terraform/
  aws-eks/     VPC (private nodes, NAT), EKS + managed node group, EBS CSI driver (IRSA), ECR
  azure-aks/   Resource group, VNet, AKS (Azure CNI overlay, managed identity, Entra ID RBAC), ACR
  gcp-gke/     VPC-native network, GKE Autopilot, Artifact Registry
k8s/
  base/        Namespace, Deployment, Service, HPA, PodDisruptionBudget, NetworkPolicies
  overlays/
    aws/       Network Load Balancer
    azure/     Load balancer health probe on /healthz
    gcp/       Backend-service-based network load balancer
.github/workflows/validate.yml   Terraform fmt + validate and Kubernetes schema checks for all three
```

The app is [podinfo](https://github.com/stefanprodan/podinfo), a small open-source web service
with health endpoints and Prometheus metrics. Each overlay sets its page message, so the running
app shows which cloud it's on.

## The same cluster, three ways

| Concern | AWS (EKS) | Azure (AKS) | Google Cloud (GKE) |
|---|---|---|---|
| Nodes | Managed node group, private subnets | System node pool in a dedicated VNet | Autopilot (Google manages nodes) |
| Pod networking | VPC CNI | Azure CNI overlay | VPC-native, secondary ranges |
| NetworkPolicy | VPC CNI network policy | Azure network policy | Dataplane V2 |
| Image registry | ECR, scan on push | ACR, pulled via kubelet managed identity | Artifact Registry |
| Cluster access | IAM, creator is admin | Entra ID + Azure RBAC | Google IAM |
| Persistent volumes | EBS CSI driver with IRSA | Built in | Built in |
| Load balancer | NLB | Azure Standard LB | Network LB |

The Kubernetes base is identical everywhere: replicas spread across zones, readiness and liveness
probes, CPU-based autoscaling, a disruption budget for node upgrades, a non-root read-only
container, and default-deny network policies.

## Deploy

Each cloud is independent. Pick one, apply its Terraform, connect kubectl, apply its overlay.

**AWS**
```bash
cd terraform/aws-eks && terraform init && terraform apply
aws eks update-kubeconfig --name darviq-eks --region ap-south-1
kubectl apply -k ../../k8s/overlays/aws
```

**Azure**
```bash
cd terraform/azure-aks && terraform init && terraform apply -var subscription_id=<your-subscription-id>
az aks get-credentials --resource-group darviq-aks-rg --name darviq-aks
kubectl apply -k ../../k8s/overlays/azure
```

**Google Cloud**
```bash
cd terraform/gcp-gke && terraform init && terraform apply -var project_id=<your-project-id>
gcloud container clusters get-credentials darviq-gke --region asia-south1 --project <your-project-id>
kubectl apply -k ../../k8s/overlays/gcp
```

Then open the load balancer address from `kubectl -n darviq-demo get svc demo-app`.

**Tear down** with `kubectl delete -k k8s/overlays/<cloud>` first (so Kubernetes removes the load
balancer it created), then `terraform destroy`. All three clouds bill for clusters, nodes and
load balancers while they run.

Defaults (regions in India, node sizes, address ranges) are in each stack's `variables.tf`.

## How it's checked

Every push runs [`validate.yml`](.github/workflows/validate.yml): `terraform fmt` and
`terraform validate` for each cloud's stack, then each overlay is rendered and checked against the
Kubernetes 1.31 schemas with kubeconform. These checks need no cloud credentials.

The AWS stack follows the same design as the EKS deployment in
[Darviq-Buzz](https://github.com/ravishekharg/Darviq-Buzz). The Azure and Google Cloud stacks are
validated in CI; apply them in a sandbox subscription or project first.

## Licence

Copyright © 2026 Darviq Systems. **All rights reserved.** Published for viewing and evaluation; see
[LICENSE](LICENSE). For licensing or help with your own multi-cloud setup, contact
[hello@darviq.com](mailto:hello@darviq.com).
