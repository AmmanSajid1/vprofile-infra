# EKS Managed Node Group Failed to Join Cluster

## Problem

During the initial deployment of the non-production EKS cluster, the EKS
control plane was created successfully but the managed node group failed to
become healthy.

Terraform eventually returned:

`NodeCreationFailure: Instances failed to join the kubernetes cluster`

The EC2 instances had been created, but they were unable to register
successfully as Kubernetes worker nodes.

## Investigation

The EKS node group health information was checked using the AWS CLI:

`aws eks describe-nodegroup`

This confirmed a `NodeCreationFailure` affecting the worker instances.

Networking was also considered because the nodes were deployed into private
subnets and depended on the NAT Gateway for outbound connectivity. However,
the required VPC routes and NAT Gateway had already been created successfully.

Attention then moved to the IAM role assigned to the worker nodes.

The node role was using:

`AmazonEKSWorkerNodeMinimalPolicy`

along with ECR pull permissions and a separate permission for EKS Pod
Identity.

Reviewing the AWS EKS IAM requirements showed that the managed node group
should instead use:

`AmazonEKSWorkerNodePolicy`

The minimal policy did not provide the permissions expected by the standard
managed worker node configuration.

## Fix

The node IAM configuration was changed to attach:

- `AmazonEKSWorkerNodePolicy`
- `AmazonEC2ContainerRegistryPullOnly`

The separate Pod Identity permission on the node role was removed because
`AmazonEKSWorkerNodePolicy` already provides the required
`eks-auth:AssumeRoleForPodIdentity` permission.

Terraform was then applied again. It replaced the failed node group while
leaving the successfully created EKS control plane intact.

Both replacement nodes successfully joined the cluster and reported:

`STATUS: Ready`

## Lesson

An EKS control plane being healthy does not mean the worker node configuration
is correct.

When managed nodes fail to join, the investigation should include the node
group health status, networking and the IAM policies attached to the node
role.

The failure also demonstrated Terraform's ability to reconcile a partially
successful deployment rather than requiring the entire environment to be
destroyed and recreated.