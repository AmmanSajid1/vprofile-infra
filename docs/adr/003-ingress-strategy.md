# ADR-004: Application Ingress

## Status
Accepted

## Decision
Replace the application's standalone NGINX entry point with an
internet-facing Application Load Balancer provisioned through the
AWS Load Balancer Controller.

TLS will terminate at the ALB using AWS Certificate Manager.

## Why
This removes an unnecessary application-managed proxy layer and uses
AWS-managed load balancing with native integration with EKS, ACM and
other AWS services.

## Trade-off
The solution is more tightly coupled to AWS than an ingress solution
such as NGINX Ingress Controller.
