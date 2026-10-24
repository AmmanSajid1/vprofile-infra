# External Secrets Helm Uninstall Stuck During Terraform Destroy

## Problem

During teardown of the non-production platform, Terraform repeatedly stalled while destroying the External Secrets Helm release.

The operation remained in progress for several minutes and had to be interrupted.

## Symptoms

Terraform repeatedly reported:

```text
helm_release.external_secrets: Still destroying...
```

After interrupting Terraform, Helm showed:

```text
external-secrets   uninstalling
```

The External Secrets controller pods had already been removed, but the Helm release had not finished uninstalling.

## Investigation

Checked the release and remaining Kubernetes resources:

```bash
helm list -A
kubectl get pods -n external-secrets
kubectl get crd externalsecrets.external-secrets.io
```

The ExternalSecret CRD was still present.

Inspected its deletion state:

```bash
kubectl get crd externalsecrets.external-secrets.io \
  -o jsonpath='Deletion timestamp: {.metadata.deletionTimestamp}{"\n"}Finalizers: {.metadata.finalizers}{"\n"}'
```

The CRD was terminating with the finalizer:

```text
customresourcecleanup.apiextensions.k8s.io
```

Seven ExternalSecret resources remained across the `dev`, `staging` and `monitoring` namespaces.

Each resource was terminating with:

```text
externalsecrets.external-secrets.io/externalsecret-cleanup
```

## Root Cause

The External Secrets controller had been removed before its remaining custom resources completed deletion.

Those resources retained cleanup finalizers normally handled by the controller.

Because the controller was no longer running, the custom resources could not finish deleting. This prevented Kubernetes from completing CRD deletion and left the Helm uninstall operation stuck.

The underlying issue was the teardown order between application-managed ExternalSecret resources and the External Secrets controller.

## Resolution

First, requested deletion of the remaining ExternalSecret resources:

```bash
kubectl delete externalsecrets.external-secrets.io --all -A --wait=false
```

The resources remained terminating because their finalizers could no longer be processed by the removed controller.

Since the cluster was being intentionally destroyed, manually removed the orphaned finalizers:

```bash
for ns in dev staging monitoring; do
  kubectl get externalsecrets.external-secrets.io -n "$ns" -o name |
  while read -r resource; do
    kubectl patch "$resource" -n "$ns" \
      --type=merge \
      -p '{"metadata":{"finalizers":[]}}'
  done
done
```

This allowed the ExternalSecret CRD to finish deleting.

Completed the interrupted Helm uninstall:

```bash
helm uninstall external-secrets -n external-secrets --no-hooks --wait=false
```

Then resumed the Terraform teardown in `platform/nonprod`.

The platform and underlying non-production infrastructure were subsequently destroyed successfully.

## Prevention

For future teardowns:

1. Remove the application resources managed by Argo CD while the External Secrets controller is still running.
2. Verify that no ExternalSecret resources remain across namespaces.
3. Destroy the monitoring and platform Terraform resources in dependency order.
4. Destroy the EKS cluster and underlying infrastructure last.

Manual finalizer removal should not be part of the normal teardown procedure. It should only be used as a recovery measure when the responsible controller is unavailable and the implications are understood.

## Lessons Learned

- Kubernetes finalizers can block deletion when the responsible controller is unavailable.
- Helm release deletion may depend on custom resources outside the release itself.
- Terraform cannot automatically resolve every Kubernetes controller dependency.
- Interrupting Terraform can leave partially deleted resources and an unfinished Helm release.
- Inspect Kubernetes and Helm state before manually modifying Terraform state.
- Teardown procedures should explicitly account for CRDs and their controllers.