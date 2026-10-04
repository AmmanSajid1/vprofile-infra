# ADR-006: EKS Administrative Access

## Status
Accepted

## Decision
Use EKS Access Entries with a dedicated platform administrator IAM role for
administrative access to the Kubernetes API.

Administrators assume the platform role rather than being granted EKS access
directly through their individual IAM user.

## Why
This separates the human identity used to authenticate to AWS from the role
used to administer the cluster.

It also provides a cleaner model for a production environment where the
platform role could be assumed through an organisation's SSO or federated
identity system.

## Trade-off
Administrators must assume an additional IAM role before accessing the cluster,
adding some configuration compared with granting an IAM user direct access.