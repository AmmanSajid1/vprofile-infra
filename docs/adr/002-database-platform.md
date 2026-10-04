# ADR-002: Database Platform

## Status
Accepted

## Decision
Run MySQL using Amazon RDS rather than inside EKS.

## Why
The database contains authoritative application data. RDS reduces the
operational burden of managing persistent storage, backups, availability
and database failover within Kubernetes.

Production will use Multi-AZ deployment. Non-production may use Single-AZ
to reduce cost.

## Trade-off
RDS increases AWS service cost and introduces greater AWS dependency.
