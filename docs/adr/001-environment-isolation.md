# ADR-002: Environment Isolation

## Status
Accepted

## Decision
Use separate EKS clusters for production and non-production.
Development and staging may share the non-production cluster using namespaces.

## Why
Namespace isolation reduces cost but does not provide a complete cluster-level
failure boundary. Separating production limits the impact of cluster-wide
misconfiguration, upgrades and failures.

## Trade-off
Additional EKS clusters increase infrastructure cost and operational overhead.
For portfolio testing, clusters may be created temporarily with Terraform and
destroyed when not required.
