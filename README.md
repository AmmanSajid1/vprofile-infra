# vProfile Infrastructure

Terraform infrastructure for deploying the vProfile application on AWS using Amazon EKS.

This repository manages the underlying AWS infrastructure and Kubernetes platform components. Application source code and Kubernetes workload configuration are maintained in separate repositories.

The project was built to practise infrastructure provisioning, environment isolation, IAM security, GitOps integration and operational troubleshooting.

## Architecture

The platform uses the following AWS and Kubernetes components:

- **Amazon VPC:** Public, private application and private database subnets, with controlled network routing.
- **Amazon EKS:** Managed Kubernetes cluster for the non-production environments.
- **Amazon RDS:** MySQL database infrastructure with separate development and staging databases.
- **Amazon ECR:** Container image storage for application and Flyway migration images.
- **AWS IAM:** Role-based access for GitHub Actions and Kubernetes workloads.
- **AWS Secrets Manager and SSM Parameter Store:** Centralised application secrets and configuration.
- **AWS Certificate Manager:** TLS certificates for application endpoints.
- **AWS Load Balancer Controller:** Application Load Balancer provisioning through Kubernetes Ingress resources.
- **ExternalDNS:** DNS record management for Kubernetes Ingress resources.
- **External Secrets Operator:** Synchronisation of AWS-managed secrets into Kubernetes.
- **Argo CD:** GitOps deployment reconciliation.
- **Prometheus, Grafana and Alertmanager:** Monitoring, dashboards and alerting.

The infrastructure supports development and staging workloads within a shared non-production EKS cluster. Each environment uses its own Kubernetes namespace and database resources.

## Repository Structure

```text
.
├── global-bootstrap/       # Terraform remote-state bootstrap
├── shared/                 # Shared AWS resources and IAM integration
├── modules/
│   ├── vpc/                # VPC, subnets and routing
│   ├── eks/                # EKS cluster and node groups
│   └── rds/                # RDS database infrastructure
├── environments/
│   └── nonprod/            # Non-production AWS infrastructure
├── platform/
│   ├── nonprod/            # Kubernetes platform services
│   └── monitoring/         # Monitoring stack
└── docs/
    ├── architecture/      # Architecture documentation
    ├── adr/               # Architecture Decision Records
    ├── troubleshooting/   # Operational troubleshooting notes
    └── deployment.md      # Deployment and teardown runbook
```

## Terraform Design

### Reusable modules

VPC, EKS and RDS are implemented as reusable Terraform modules.

Environment-specific configuration is kept outside these modules, allowing infrastructure sizing, networking and other settings to be managed independently.

### Remote state

Terraform state is stored remotely in Amazon S3.

The remote-state infrastructure is managed separately from the application environments to reduce the risk of accidentally destroying the state backend during environment teardown.

Separate Terraform root configurations are used for shared resources, non-production infrastructure, Kubernetes platform components and monitoring.

### Infrastructure lifecycle

The infrastructure is divided into layers with different lifecycles:

1. **Global bootstrap:** Remote-state infrastructure.
2. **Shared resources:** Resources that persist independently of the EKS environment.
3. **Non-production infrastructure:** VPC, EKS, RDS and associated IAM configuration.
4. **Kubernetes platform:** Argo CD, AWS controllers, External Secrets Operator and supporting services.
5. **Monitoring:** Prometheus, Grafana and Alertmanager.

This separation allows expensive infrastructure components to be destroyed without necessarily removing shared resources.

## Security

The infrastructure incorporates several security controls:

- IAM roles and scoped permissions for AWS access.
- GitHub Actions authentication through AWS OIDC rather than long-lived AWS access keys.
- Kubernetes workload access to AWS services through EKS Pod Identity.
- Private networking for application and database infrastructure.
- Database access controlled through security groups.
- Secrets stored in AWS Secrets Manager and SSM Parameter Store rather than committed to Git.
- HTTPS application endpoints using ACM certificates and Application Load Balancers.
- Controlled EKS administrative access.

The relevant implementation decisions are documented in the architecture decision records.

## Environment Isolation

Development and staging share the non-production EKS cluster but use separate namespaces, application configuration, secrets and database resources.

The staging environment was introduced to validate releases before promotion beyond development.

Container images are built once by the application CI pipeline and promoted between environments using immutable Git SHA tags.

A production Kustomize overlay exists in the GitOps repository, but a production infrastructure environment has not been implemented.

## Monitoring and Operations

The monitoring stack is managed as a separate Terraform layer.

Prometheus collects Kubernetes and workload metrics, Grafana provides dashboards, and Alertmanager supports alert routing.

Separating monitoring from the core infrastructure configuration makes its lifecycle and resource ownership more explicit.

Operational investigations, including EKS node provisioning, scheduling capacity, access configuration and Grafana resource pressure, are recorded under `docs/troubleshooting/`.

## Deployment and Teardown

The platform has been deployed and tested, including development and staging application endpoints, database integration, GitOps reconciliation and monitoring.

**The cost-incurring non-production infrastructure is currently destroyed to avoid ongoing AWS charges.** Shared and bootstrap resources are managed separately.

Provisioning and teardown should follow the documented dependency order to avoid issues with Kubernetes resources, Helm releases and AWS infrastructure dependencies.

See the [Deployment and Teardown Runbook](docs/deployment.md) for the procedures.

## Related Repositories

- [vprofile-app](https://github.com/AmmanSajid1/vprofile-app) — Application source code, Docker images, database migrations and GitHub Actions CI/CD.
- [vprofile-gitops](https://github.com/AmmanSajid1/vprofile-gitops) — Kubernetes manifests, Kustomize overlays, Argo CD Applications and image promotion configuration.

## Documentation

### Architecture

- [Architecture Overview](docs/architecture/README.md)
- [Deployment and Teardown Runbook](docs/deployment.md)

### Architecture Decision Records

- [ADR 001 — Environment Isolation](docs/adr/001-environment-isolation.md)
- [ADR 002 — Database Platform](docs/adr/002-database-platform.md)
- [ADR 003 — Ingress Strategy](docs/adr/003-ingress-strategy.md)
- [ADR 004 — Network Availability](docs/adr/004-network-availability.md)
- [ADR 005 — EKS Pod Identity](docs/adr/005-eks-pod-identity.md)
- [ADR 006 — EKS Administrative Access](docs/adr/006-eks-administrative-access.md)
- [ADR 007 — Shared ACM Certificate Lifecycle](docs/adr/007-shared-acm-certificate-lifecycle.md)
- [ADR 008 — Monitoring Stack Architecture](docs/adr/008-monitoring-stack-architecture.md)
- [ADR 009 — Staging Database Isolation](docs/adr/009-staging-database-isolation.md)

### Troubleshooting

- [EKS Access Entry Dependency](docs/troubleshooting/eks-access-entry-dependency.md)
- [EKS Node Group Failed to Join](docs/troubleshooting/eks-node-group-failed-to-join.md)
- [EKS Pod Scheduling Capacity](docs/troubleshooting/eks-pod-scheduling-capacity.md)
- [External Secrets Helm Uninstall Stuck](docs/troubleshooting/external-secrets-helm-uninstall-stuck.md)
- [Grafana Readiness and Resource Pressure](docs/troubleshooting/grafana-readiness-and-resource-pressure.md)