# vProfile AWS/EKS Architecture

## Business Scenario

vProfile is an existing customer-facing application being modernised onto AWS and Kubernetes.

The platform should provide:

- Automated and auditable deployments
- Production environment isolation
- High availability across multiple Availability Zones
- Secure configuration management
- Reduced operational overhead through managed AWS services where appropriate
- Cost-conscious infrastructure without sacrificing important production resilience

Production represents the target architecture. Non-production and temporary portfolio deployments may use reduced redundancy to control AWS costs.

---

## Runtime Architecture

```text
                              INTERNET
                                 │
                                 │ HTTPS
                                 ▼
                        app.ammandevops.xyz
                                 │
                             Route 53
                                 │
                                 ▼
                   ┌─────────────────────────┐
                   │ Internet-facing ALB     │
                   │ TLS termination (ACM)   │
                   └────────────┬────────────┘
                                │
                 ┌──────────────┴──────────────┐
                 │                             │
              AZ-A                           AZ-B
        ┌────────────────┐             ┌────────────────┐
        │ Public Subnet  │             │ Public Subnet  │
        │                │             │                │
        │ ALB            │             │ ALB            │
        │ NAT Gateway    │             │ NAT Gateway    │
        └───────┬────────┘             └───────┬────────┘
                │                              │
        ┌───────▼────────┐             ┌───────▼────────┐
        │ Private App    │             │ Private App    │
        │ Subnet         │             │ Subnet         │
        │                │             │                │
        │   EKS Nodes    │             │   EKS Nodes    │
        └───────┬────────┘             └────────┬───────┘
                │                               │
                └──────────────┬────────────────┘
                               │
                   ┌───────────▼───────────┐
                   │      EKS Cluster      │
                   │                       │
                   │ vProfile / Tomcat     │
                   │ Memcached             │
                   │ RabbitMQ              │
                   │ Argo CD               │
                   │ AWS LB Controller     │
                   └───────────┬───────────┘
                               │
                               │ MySQL :3306
                               ▼
             ┌─────────────────────────────────┐
             │          Private DB Tier        │
             │                                 │
             │ DB Subnet A       DB Subnet B   │
             │        \             /          │
             │         \           /           │
             │          RDS MySQL              │
             │      Multi-AZ (production)      │
             └─────────────────────────────────┘
```

---

## Delivery / Control Plane

```text
GitHub ──────► GitHub Actions ──────► Amazon ECR
   │                                      │
   │                                      │ image pull
   │                                      ▼
   │                                 EKS workloads
   │
   └────────► GitOps Repository
                    │
                    │ watched / reconciled
                    ▼
                 Argo CD
                    │
                    ▼
                   EKS
```

GitHub Actions handles CI and publishes application images to ECR.  
Argo CD continuously reconciles the desired state stored in the GitOps repository with EKS.

---

## Key Decisions

- Separate **production and non-production EKS clusters**
- **RDS MySQL** instead of running the database inside Kubernetes
- **Multi-AZ RDS** for production; reduced redundancy permitted in non-production
- **ALB + AWS Load Balancer Controller** instead of the inherited NGINX entry point
- **ACM** for TLS and **Route 53** for DNS
- **ECR** for application container images
- Production spans **two Availability Zones**
- Production uses **one NAT Gateway per AZ**
- Memcached and RabbitMQ run inside EKS
- Temporary portfolio deployments may reduce redundancy to control cost

---

## Architecture Decision Records

Detailed reasoning for major decisions is recorded in [`../adr/`](../adr/).

- [ADR-001: Environment Isolation](../adr/001-environment-isolation.md)
- [ADR-002: Database Platform](../adr/002-database-platform.md)
- [ADR-003: Application Ingress](../adr/003-ingress-strategy.md)
- [ADR-004: Network Availability](../adr/004-network-availability.md)