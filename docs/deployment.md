
# Deployment Runbook

This document describes the bootstrap sequence for the vProfile non-production AWS/EKS environment.

## Prerequisites

- AWS CLI authenticated with the required IAM permissions
- Terraform, kubectl and Helm installed
- Access to the `vprofile-infra` and `vprofile-gitops` repositories
- EKS administrator access configured

## Deployment Order

### 1. Terraform Backend

From the `vprofile-infra` repository:

```bash
cd global-bootstrap
terraform init
terraform apply
```

The backend must exist before the other Terraform roots can use remote state.

### 2. Shared AWS Resources

```bash
cd ../shared
terraform init
terraform apply
```

Provisions shared resources including ACM certificates, GitHub OIDC and application secrets.

### 3. Non-Production Infrastructure

```bash
cd ../environments/nonprod
terraform init
terraform apply
```

Provisions the VPC, EKS cluster, RDS and supporting IAM resources.

Configure kubectl access to the EKS cluster using the appropriate IAM role, then verify the worker nodes:

```bash
kubectl get nodes
```

Both worker nodes should report `Ready`.

### 4. Core Kubernetes Platform

```bash
cd ../../platform/nonprod
terraform init
terraform apply
```

Installs:

- Argo CD
- External Secrets Operator
- AWS Load Balancer Controller
- ExternalDNS
- gp3 StorageClass

### 5. Bootstrap Monitoring Secrets Through GitOps

From the `vprofile-gitops` repository:

```bash
kubectl apply -f argocd/applications/monitoring.yaml
```

The Argo CD Application has automated synchronization enabled, so it deploys the resources defined under `platform/monitoring/`:

- `secret-store.yaml`
- `external-secret.yaml`

External Secrets Operator retrieves the Grafana credentials from AWS Secrets Manager and creates the Kubernetes Secret.

Verify the ExternalSecret:

```bash
kubectl get externalsecret grafana-admin -n monitoring
```

Its `Ready` status should be `True`.

Verify the Kubernetes Secret:

```bash
kubectl get secret grafana-admin-credentials -n monitoring
```

**Do not install the monitoring Helm chart until the Grafana Secret exists.**

This dependency is important because Grafana requires the Secret during startup. Installing the chart before the Secret is created can cause the Helm deployment to time out.

### 6. Install Monitoring

From the `vprofile-infra` repository:

```bash
cd platform/monitoring
terraform init
terraform apply
```

Installs the `kube-prometheus-stack` Helm chart, including:

- Prometheus
- Grafana
- Alertmanager
- Prometheus Operator
- kube-state-metrics
- Node Exporter

Verify the monitoring workloads:

```bash
kubectl get pods -n monitoring
```

Verify Terraform configuration and state:

```bash
terraform plan
```

Terraform should report:

```text
No changes. Your infrastructure matches the configuration.
```

## Teardown

Destroy resources in reverse dependency order, after removing application workloads and GitOps-managed resources.

Suggested sequence:

1. Remove application workloads and relevant Argo CD Applications.
2. Destroy `platform/monitoring`.
3. Destroy `platform/nonprod`.
4. Destroy `environments/nonprod`.
5. Destroy `shared` only if its resources are no longer needed.
6. Destroy `global-bootstrap` only when all dependent Terraform states have been safely retired.

Review every Terraform destroy plan before proceeding.

Some resources, including RDS databases, AWS Secrets Manager secrets, ACM certificates and Terraform state storage, may require additional protection or manual handling.

Do not destroy shared infrastructure while other environments or applications still depend on it.
