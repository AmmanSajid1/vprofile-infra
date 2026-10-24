# Deployment Runbook

This document describes the deployment, verification and teardown procedures for the vProfile non-production AWS/EKS environment.

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

Provisions the VPC, EKS cluster, development and staging RDS instances, and supporting IAM resources.

Configure kubectl access to the EKS cluster using the appropriate IAM role, then verify the worker nodes:

```bash
kubectl get nodes
```

All provisioned worker nodes should report `Ready`.

The cluster initially used two `t3.medium` nodes. During staging deployment, this was increased to three nodes after reaching the pod scheduling limit.

See `docs/troubleshooting/eks-pod-scheduling-capacity.md` for details.

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

Verify the platform components:

```bash
kubectl get pods -n argocd
kubectl get pods -n external-secrets
kubectl get pods -n kube-system
```

Ensure the controllers are healthy before deploying application resources that depend on them.

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

If Grafana experiences readiness or responsiveness problems, see `docs/troubleshooting/grafana-readiness-and-resource-pressure.md`.

### 7. Deploy Development and Staging Applications

From the `vprofile-gitops` repository, apply the Argo CD Applications:

```bash
kubectl apply -f argocd/applications/vprofile-dev.yaml
kubectl apply -f argocd/applications/vprofile-staging.yaml
```

Argo CD reconciles the environment-specific Kubernetes manifests from:

- `apps/vprofile/overlays/dev/`
- `apps/vprofile/overlays/staging/`

Both environments run in the same EKS cluster but use separate namespaces and RDS instances.

Each environment has its own database credentials and configuration managed through AWS Secrets Manager, SSM Parameter Store and External Secrets Operator.

The application components include:

- Tomcat application
- Nginx reverse proxy
- Memcached
- RabbitMQ

Database initialization and Flyway migrations must complete successfully before validating application functionality.

Check Argo CD synchronization:

```bash
kubectl get applications -n argocd
```

Check the workloads:

```bash
kubectl get pods -n dev
kubectl get pods -n staging
```

Both applications should report `Synced / Healthy` in Argo CD, with the required deployments ready.

If pods remain `Pending`, inspect Kubernetes scheduler events before changing resource allocations.

### 8. Verify Application Deployment

Verify the development environment:

`https://dev.ammandevops.xyz`

Verify the staging environment:

`https://staging.ammandevops.xyz`

Both environments use HTTPS through an AWS Application Load Balancer and a shared ACM certificate.

The ingresses share the ALB through the `vprofile-nonprod` ingress group.

Verify:

- Both URLs load successfully over HTTPS.
- Application registration and login work.
- Development and staging use separate databases.
- A user registered in one environment cannot authenticate in the other.
- Database migrations have completed successfully.
- Argo CD reports both applications as `Synced / Healthy`.

Both environments can deploy the same immutable ECR image while maintaining independent configuration and application data.

### 9. Final Infrastructure Verification

Run `terraform plan` in each relevant Terraform root to confirm the deployed infrastructure matches its configuration.

Check the EKS workloads:

```bash
kubectl get nodes
kubectl get applications -n argocd
kubectl get pods -A
```

Review unexpected pod restarts, pending workloads and unhealthy Argo CD Applications before considering the deployment complete.

## Non-Production Teardown

The non-production infrastructure is intentionally temporary to reduce AWS costs.

Destroy resources in dependency order, ensuring Kubernetes-managed resources are removed before their supporting controllers and the EKS cluster.

### 1. Remove Argo CD Applications

Before removing platform controllers, delete the application resources managed by Argo CD.

```bash
kubectl delete application vprofile-dev -n argocd --cascade=foreground
kubectl delete application vprofile-staging -n argocd --cascade=foreground
kubectl delete application monitoring -n argocd --cascade=foreground
```

Wait for application resources to be deleted.

Verify:

```bash
kubectl get applications -n argocd
kubectl get pods -n dev
kubectl get pods -n staging
```

**Important:** Do not proceed solely because the Argo CD Application objects have disappeared. Verify that their managed resources, particularly Ingresses and ExternalSecrets, have also been removed.

### 2. Verify External Secrets Cleanup

The External Secrets controller must remain running until its custom resources have finished deleting.

Check for remaining ExternalSecret resources:

```bash
kubectl get externalsecrets.external-secrets.io -A
```

The command should report no remaining ExternalSecret resources.

If any resources remain, investigate their deletion state before continuing.

Do not uninstall External Secrets Operator while its custom resources are still terminating.

This prevents a known failure where the Helm uninstall becomes stuck because ExternalSecret finalizers cannot be processed after the controller is removed.

See `docs/troubleshooting/external-secrets-helm-uninstall-stuck.md` for the investigation and recovery procedure.

### 3. Verify Load Balancer Cleanup

The AWS Load Balancer Controller should remain running until application Ingress resources have been deleted and their associated AWS load balancers have been cleaned up.

Check for remaining Ingress resources:

```bash
kubectl get ingress -A
```

Verify that the non-production Application Load Balancer has been removed from AWS.

Do not destroy the AWS Load Balancer Controller or VPC while an application-managed ALB remains.

### 4. Destroy Monitoring

From the `vprofile-infra` repository:

```bash
cd platform/monitoring
terraform plan -destroy
terraform destroy
```

Review the destroy plan before confirming.

This removes the Terraform-managed monitoring components.

Check for remaining monitoring resources if the destroy operation reports errors.

### 5. Destroy Core Kubernetes Platform

```bash
cd ../nonprod
terraform plan -destroy
terraform destroy
```

This removes Terraform-managed platform components, including:

- Argo CD
- External Secrets Operator
- AWS Load Balancer Controller
- ExternalDNS
- Platform storage configuration

Review the destroy plan before confirming.

If a Helm release becomes stuck uninstalling, inspect its status and any remaining custom resources before retrying.

Avoid manually removing Terraform state entries as a first troubleshooting step.

### 6. Destroy Non-Production Infrastructure

```bash
cd ../../environments/nonprod
terraform plan -destroy
terraform destroy
```

This removes the non-production infrastructure, including:

- EKS cluster and managed node group
- Development and staging RDS instances
- VPC networking
- NAT gateways and associated networking resources
- Environment-specific IAM and supporting resources

**Warning:** Destroying the development and staging RDS instances can permanently delete their data. The non-production configuration may skip final snapshots.

Review the destroy plan carefully before confirming.

### 7. Verify AWS Resource Cleanup

After Terraform completes, verify that expensive infrastructure resources have been removed.

Check EKS clusters:

```bash
aws eks list-clusters --region us-east-1
```

Check RDS instances:

```bash
aws rds describe-db-instances \
  --region us-east-1 \
  --query 'DBInstances[].{ID:DBInstanceIdentifier,Status:DBInstanceStatus}' \
  --output table
```

Check Application Load Balancers:

```bash
aws elbv2 describe-load-balancers \
  --region us-east-1 \
  --query 'LoadBalancers[].{Name:LoadBalancerName,State:State.Code}' \
  --output table
```

Check active NAT gateways:

```bash
aws ec2 describe-nat-gateways \
  --region us-east-1 \
  --filter Name=state,Values=available,pending \
  --query 'NatGateways[].NatGatewayId' \
  --output text
```

Also check for orphaned EBS volumes, Elastic IPs and other resources that may continue incurring charges.

Review the remaining Terraform state in each destroyed root:

```bash
terraform state list
```

An empty state is expected after a successful full destroy.

### 8. Preserve Shared Infrastructure

The following Terraform roots can remain provisioned between testing sessions:

- `shared`
- `global-bootstrap`

These contain reusable resources such as ACM certificates, GitHub OIDC configuration, application secrets and Terraform remote-state infrastructure.

Do not destroy shared infrastructure while other environments or applications still depend on it.

Shared resources may still incur AWS charges.

Destroy `shared` only when its resources are no longer required.

Destroy `global-bootstrap` only after all dependent Terraform states have been safely retired and any required state backups have been preserved.

## Operational Notes

- Apply infrastructure changes through Terraform rather than manually modifying managed resources.
- Use GitOps to manage application Kubernetes resources.
- Remove Kubernetes custom resources before uninstalling the controllers responsible for their finalizers.
- Allow Kubernetes controllers to clean up AWS resources before destroying the underlying infrastructure.
- Review Terraform plans before applying or destroying resources.
- Verify AWS resource cleanup after teardown rather than assuming a successful Terraform destroy removed every resource.
- Keep development and staging data isolated, even when the environments share an EKS cluster.
- Destroy temporary infrastructure when it is no longer required to minimise AWS costs.