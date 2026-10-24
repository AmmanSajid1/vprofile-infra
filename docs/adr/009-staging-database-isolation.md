# ADR-009: Staging Database Isolation

## Status
Accepted

## Context

ADR-001 established that development and staging may share the non-production EKS cluster using separate Kubernetes namespaces.

ADR-002 established Amazon RDS MySQL as the database platform.

When introducing staging, we needed to ensure that application testing would not affect development data, while keeping infrastructure costs manageable.

## Decision

Deploy development and staging into separate namespaces within the same non-production EKS cluster, but provision a dedicated Amazon RDS MySQL instance for each environment.

Each environment uses its own:

- RDS instance and database users.
- AWS Secrets Manager application and migration credentials.
- SSM Parameter Store database endpoint configuration.
- IAM roles and EKS Pod Identity associations for database bootstrap and Flyway migrations.
- ExternalSecret resources and Kubernetes Secrets.

Both environments deploy application images from the same Amazon ECR repositories.

For non-production testing, RDS instances use Single-AZ deployments to reduce cost.

## Why

Separate databases allow staging to test schema migrations, registration and authentication without modifying development data.

Reusing the EKS cluster reduces costs while still demonstrating namespace-scoped deployments, environment-specific configuration and GitOps management.

Using separate credentials and Pod Identity roles limits access for the database bootstrap and migration workloads.

## Verification

The staging deployment was synchronised successfully through Argo CD.

Database bootstrap and Flyway migration jobs completed successfully.

Application registration and login were tested in both environments:

- A user registered in development could not log in to staging.
- A user registered in staging could log in to staging.
- The staging user could not log in to development.

Both environments were verified to use the same immutable ECR application image tag.

## Trade-offs and Limitations

- Both environments share EKS worker nodes and cluster-level services, so namespace isolation does not provide a complete failure boundary.
- Separate RDS instances increase infrastructure costs.
- Shared platform components, including the External Secrets controller, create operational dependencies.
- Some infrastructure access remains shared, including the central External Secrets IAM role and EKS cluster security group.
- Production requires stronger isolation, as described in ADR-001.

## Future Improvements

- Implement a GitHub Actions workflow to propose dev-to-staging image promotion through a pull request.
- Introduce environment-specific approval and validation requirements.
- Evaluate stronger IAM and network isolation where required.
- Keep production in a separate cluster and preferably a separate AWS account.