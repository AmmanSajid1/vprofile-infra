# ADR 008: Kubernetes Monitoring Stack Architecture

**Status:** Accepted

## Context

The vProfile application runs on Amazon EKS, with workloads managed through Argo CD.

We needed visibility into cluster health, resource consumption and application dependencies to support troubleshooting and capacity planning.

The monitoring solution needed to be reproducible through Terraform, reasonably cost-effective for a non-production environment, and capable of supporting application-specific metrics in the future.

## Decision

Deploy the Prometheus community `kube-prometheus-stack` Helm chart through Terraform.

The stack includes:

- **Prometheus:** Collects and stores metrics.
- **Grafana:** Provides dashboards and metric exploration.
- **Alertmanager:** Provides infrastructure for future alert routing.
- **Prometheus Operator:** Manages Prometheus resources and monitoring configuration.
- **kube-state-metrics:** Exposes Kubernetes object-state metrics.
- **Node Exporter:** Exposes node-level operating system metrics.

### Infrastructure management

Terraform manages the Helm release in `platform/nonprod`.

The monitoring stack runs in a dedicated `monitoring` namespace.

Prometheus and Grafana use internal `ClusterIP` services. Access to Grafana is provided through Kubernetes port forwarding rather than a public load balancer.

### Persistent metrics storage

Prometheus uses a 10 GiB persistent volume provisioned through the AWS EBS CSI driver and a Terraform-managed `gp3` StorageClass.

The volume uses `WaitForFirstConsumer` binding and `Delete` reclaim policy.

Prometheus is configured with seven-day retention and an 8 GB retention-size limit.

This provides persistent metrics storage across ordinary pod restarts while limiting storage consumption.

### Resource constraints

The stack uses a single Prometheus replica and a single Grafana replica to reduce resource requirements.

CPU and memory requests and limits are configured to fit the non-production cluster.

Grafana's memory allocation was increased following readiness and responsiveness problems observed during initial deployment.

### Application-specific monitoring

Prometheus Operator `ServiceMonitor` resources are used to discover additional metrics endpoints.

RabbitMQ exposes Prometheus metrics through port `15692`. Its Service and ServiceMonitor are maintained in the GitOps repository alongside the application configuration.

This separates platform installation from application-specific monitoring configuration.

## Alternatives considered

### Amazon Managed Service for Prometheus and Amazon Managed Grafana

AWS-managed services reduce the operational burden of running monitoring infrastructure.

Not selected for this learning environment because we wanted direct experience operating the monitoring stack and controlling its configuration.

### Installing individual monitoring components

Deploying Prometheus, Grafana and supporting exporters separately provides more flexibility.

Not selected because `kube-prometheus-stack` offers a consistent, operator-managed installation.

### Ephemeral Prometheus storage

Avoids provisioning an EBS volume but loses historical metrics when the pod is recreated.

Rejected in favour of persistent storage.

## Consequences

### Benefits

- Reproducible monitoring deployment through Terraform.
- Cluster-level and namespace-level visibility.
- Persistent metrics with bounded retention.
- Extensible monitoring through ServiceMonitor resources.
- No additional public load balancer for Grafana.

### Trade-offs and limitations

- Monitoring workloads consume CPU and memory on the existing EKS nodes.
- The monitoring stack introduces Helm, CRDs and additional operational complexity.
- Single-replica Prometheus and Grafana are not highly available.
- EBS volumes are tied to an Availability Zone.
- Prometheus storage incurs AWS charges while provisioned.
- Alertmanager is installed, but production notification routing has not yet been configured.

## Future improvements

- Add application-level HTTP and JVM metrics.
- Configure useful Prometheus alerting rules.
- Add notification routing through Alertmanager.
- Evaluate managed monitoring services for production environments.
- Introduce more robust availability and retention policies for production.