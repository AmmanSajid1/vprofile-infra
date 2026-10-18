# Grafana Readiness and Resource Pressure

## Problem

After deploying `kube-prometheus-stack` to the non-production EKS cluster, Grafana was initially accessible but became unresponsive after login.

The interface remained stuck loading, and the Grafana pod was not consistently healthy.

## Symptoms

- Grafana login succeeded, but the interface failed to load properly.
- The Grafana pod reported only `2/3` containers ready.
- Grafana API requests were slow or timed out.
- Container logs reported SQLite database contention, including database busy/locked messages.
- Kubernetes liveness probe failures caused container restarts.
- One container termination reported exit code `137`.

## Investigation

Checked pod status and restart counts:

```bash
kubectl get pods -n monitoring
```

Inspected pod events and container termination information:

```bash
kubectl describe pod -n monitoring <grafana-pod>
```

Reviewed Grafana container logs:

```bash
kubectl logs -n monitoring <grafana-pod> -c grafana
```

The investigation showed that Grafana was struggling to respond reliably while operating with a relatively small resource allocation.

The original Terraform Helm configuration used:

| Resource | Original |
|---|---|
| CPU request | 50m |
| Memory request | 128Mi |
| Memory limit | 256Mi |

The SQLite contention and slow API responses suggested resource pressure was contributing to the instability.

Exit code `137` indicated the process had been killed, although that alone did not establish whether the cause was an out-of-memory kill or a forced termination following failed health checks.

## Resolution

Increased Grafana's resource allocation in the Terraform-managed Helm values:

| Resource | Updated |
|---|---|
| CPU request | 100m |
| Memory request | 256Mi |
| Memory limit | 512Mi |

Applied the Terraform changes to update the Helm release.

## Verification

Following the update:

- The replacement Grafana pod reached `3/3` containers ready.
- No container restarts were observed during verification.
- The Grafana interface loaded successfully.
- The Prometheus data source passed its connection test.
- Kubernetes cluster and namespace dashboards displayed metrics.

## Root cause assessment

The evidence was consistent with Grafana experiencing insufficient resources for reliable startup and operation.

Increasing CPU and memory allocations resolved the observed symptoms.

However, the exact termination mechanism was not conclusively established, so this should not be described as a confirmed OOM incident.

## Lessons learned

- A successful Helm installation does not guarantee that every application is operational.
- Kubernetes readiness, liveness, logs and termination details should be investigated together.
- Exit code `137` does not automatically prove an OOM kill.
- Resource requests and limits should be validated against actual workload behaviour.
- Infrastructure changes should be applied through Terraform rather than manual modifications that introduce configuration drift.