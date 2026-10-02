# ADR-005: Network Availability

## Status
Accepted

## Decision
Deploy production infrastructure across two Availability Zones with
public, private application and private database subnets in each AZ.

Production will use one NAT Gateway per AZ.

## Why
Multi-AZ placement reduces dependency on a single Availability Zone.
Per-AZ NAT Gateways avoid making private workloads in both AZs dependent
on a single NAT Gateway.

## Trade-off
The additional NAT Gateway increases cost. Temporary portfolio deployments
may use one NAT Gateway as an explicit cost optimisation.
