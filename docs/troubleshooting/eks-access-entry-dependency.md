# EKS Access Entry Terraform Dependency Issues

## Problem

While configuring administrative access to the EKS cluster, two Terraform
issues were encountered around EKS Access Entries.

The first occurred after renaming an already-managed Terraform access entry
resource. Terraform treated the new resource address as a new resource while
attempting to remove the old one, resulting in an AWS
`ResourceInUseException`.

After reconciling the Terraform state with the resources that actually
existed in AWS, a second issue occurred.

Terraform attempted to create the EKS Access Entry and associate
`AmazonEKSClusterAdminPolicy` with it at approximately the same time.

The policy association failed with `ResourceNotFoundException` because the
Access Entry was not yet available when AWS processed the association request.

## Investigation

Terraform state and AWS were checked separately to determine what had
successfully been created.

`terraform state list` was used to inspect Terraform's current view of the
resources.

The AWS CLI was then used to inspect the actual EKS Access Entries:

`aws eks list-access-entries`

After the state/resource mismatch was resolved, the Terraform plan showed the
expected Access Entry and policy association.

The subsequent failure showed that Terraform considered the two resources
independent enough to create concurrently.

Both resources referenced the platform administrator IAM role, but the policy
association did not reference the Access Entry resource itself. Terraform
therefore had no dependency requiring the Access Entry to be created first.

## Fix

An explicit dependency was added to the policy association:

```hcl
depends_on = [
  aws_eks_access_entry.platform_admin
]
```
Terraform then created the Access Entry before attempting the policy
association.

The deployment completed successfully.

## Lesson

Terraform determines creation order from its dependency graph rather than from
the logical relationship between resources in AWS.

When one AWS resource must exist before another operation can succeed, an
explicit depends_on may be required if Terraform cannot infer that
dependency from resource references.

Renaming a Terraform resource is also not purely cosmetic. Once a resource is
tracked in state, changing its Terraform address can cause Terraform to treat
it as a destroy/create operation. Resource moves should therefore be handled
deliberately, for example with a Terraform moved block when appropriate.