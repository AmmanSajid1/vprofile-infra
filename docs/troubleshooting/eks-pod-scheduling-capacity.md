# EKS Pods Pending Due to Pod Capacity Limits

## Problem

During deployment of the staging environment, the Memcached pod remained in `Pending` and the application deployment could not complete.

Argo CD reported `OutOfSync / Progressing`, although the staging database bootstrap and Flyway migration jobs had completed successfully.

## Symptoms

- Staging Memcached pod remained `Pending`.
- RabbitMQ was running, but the Tomcat application had not yet deployed.
- Argo CD could not complete reconciliation.
- Kubernetes reported a scheduling failure.

## Investigation

Inspected the pending pod:

```bash
kubectl describe pod <pod-name> -n staging
```

The scheduler reported:

```text
0/2 nodes are available: 2 Too many pods.
```

Checked the node types and pod limits:

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,INSTANCE:.metadata.labels.node\\.kubernetes\\.io/instance-type,MAX_PODS:.status.allocatable.pods
```

Both worker nodes were `t3.medium` instances, with a maximum of 17 pods each.

Further inspection confirmed that both nodes had reached their pod allocation limits:

```bash
kubectl describe nodes
```

The cluster was already hosting Argo CD, Prometheus, Grafana, External Secrets, AWS controllers, Kubernetes system workloads and the development application.

## Root Cause

The existing two-node EKS cluster had insufficient pod scheduling capacity to accommodate the additional staging workloads.

The scheduler explicitly reported that the maximum pod count had been reached. The evidence did not indicate that CPU or memory exhaustion was the immediate scheduling constraint.

## Resolution

Updated `environments/nonprod/terraform.tfvars` to increase the EKS managed node group's desired capacity from two to three:

```hcl
node_desired_capacity = 3
node_max_capacity     = 3
node_min_capacity     = 1
```

Terraform reported one in-place update:

```text
Plan: 0 to add, 1 to change, 0 to destroy.
```

After applying the change, a third worker node joined the cluster.

Kubernetes scheduled the remaining staging workloads without requiring changes to the application manifests.

## Verification

Checked the nodes and staging resources:

```bash
kubectl get nodes
kubectl get pods,deployments -n staging
kubectl get applications -n argocd vprofile-staging
```

All three staging deployments reached `1/1 Ready`:

- vProfile application
- Memcached
- RabbitMQ

Argo CD reported `Synced / Healthy`.

The staging application was subsequently tested successfully over HTTPS.

## Lessons Learned

- Investigate Kubernetes scheduler events before changing resource allocations.
- Pod-count limits are distinct from CPU and memory capacity.
- Platform services must be included when planning node capacity.
- EKS pod density depends on instance type and networking configuration.
- Node group scaling should be managed through Terraform to avoid configuration drift.
- Temporary infrastructure should be scaled down or destroyed after testing to control costs.