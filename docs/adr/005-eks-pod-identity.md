# ADR-005: EKS Workload Identity

## Status
Accepted

## Decision
Use EKS Pod Identity for AWS permissions required by workloads running in the
EKS cluster rather than IAM Roles for Service Accounts (IRSA).

## Why
Pod Identity provides a simpler way to associate IAM roles with Kubernetes
service accounts without managing an OIDC provider for each EKS cluster.

It also keeps AWS permissions separate from the EC2 worker node role, allowing
workloads to receive only the permissions they require.

## Trade-off
EKS Pod Identity requires the Pod Identity Agent to run in the cluster and is
specific to EKS. IRSA has broader compatibility and may still be preferable
where Pod Identity is not supported.