# ADR 007: Shared ACM Certificate Lifecycle

**Status:** Accepted  

## Context

The vProfile application requires HTTPS across three environments:

- Development: `dev.ammandevops.xyz`
- Staging: `staging.ammandevops.xyz`
- Production: `app.ammandevops.xyz`

Each environment uses an AWS Application Load Balancer (ALB) provisioned by the AWS Load Balancer Controller.

Development and staging share an ALB in the non-production EKS cluster, while production uses a dedicated ALB in a separate cluster.

TLS certificates must be available before the ALBs can be configured for HTTPS.

During development, the non-production and production infrastructure may be created and destroyed frequently to control AWS costs.

We needed an approach that would preserve certificates across environment rebuilds, avoid unnecessary certificate reissuance and integrate with our existing DNS configuration.

## Decision

### 1. Manage ACM certificates in shared Terraform infrastructure

Provision ACM certificates in the `shared/` Terraform root rather than within `environments/nonprod/` or `environments/prod/`.

The shared infrastructure has an independent lifecycle from the EKS environments.

This allows us to destroy temporary EKS infrastructure without destroying the certificates required for future deployments.

Certificates are managed in AWS Certificate Manager in `us-east-1`, matching the region where the ALBs will be deployed.

### 2. Use separate certificates for non-production and production

Provision two certificates:

| Environment | Certificate domains |
|---|---|
| Non-production | `dev.ammandevops.xyz`, `staging.ammandevops.xyz` |
| Production | `app.ammandevops.xyz` |

The non-production certificate covers both development and staging using a primary domain and Subject Alternative Name (SAN).

Production uses a separate certificate to maintain an independent certificate lifecycle.

This avoids coupling production certificate changes to non-production requirements.

The domains are defined through the Terraform `domain_map_env` variable.

### 3. Reuse the existing Route 53 hosted zone

The domain `ammandevops.xyz` already has a Route 53 public hosted zone, with its authoritative name servers configured through GoDaddy.

Terraform retrieves the existing hosted zone using a data source rather than creating another hosted zone.

This avoids unnecessary DNS infrastructure and prevents accidental duplication of the existing zone.

### 4. Automate DNS validation

Use ACM DNS validation rather than email validation.

Terraform creates the validation CNAME records in Route 53 using the certificate's `domain_validation_options`.

The implementation uses:

- `aws_acm_certificate` to request certificates.
- `aws_route53_record` to create DNS validation records.
- `aws_acm_certificate_validation` to wait for certificate issuance.

The validation records are generated dynamically to support certificates containing multiple domain names.

The certificate resources use `create_before_destroy` to reduce disruption during certificate replacement, although replacement can still require coordination with ALB consumers.

### 5. Expose certificate ARNs through Terraform outputs

The shared Terraform root exposes certificate ARNs using the `acm_certificate_arns` output.

These ARNs are referenced by the corresponding Kubernetes Ingress resources through:

```yaml
alb.ingress.kubernetes.io/certificate-arn: <certificate-arn>
```

The certificate ARN is not a secret and can be stored in the GitOps repository.

However, the ARN creates a dependency between the GitOps configuration and the shared Terraform infrastructure.

If a certificate is replaced and receives a new ARN, the relevant Ingress configuration must be updated.

### 6. Keep DNS validation separate from application DNS routing

ACM DNS validation records prove domain ownership and allow certificates to be issued.

They do not automatically route application traffic to an ALB.

Application DNS records for `dev`, `staging` and `app` must be configured separately once the relevant ALBs have been provisioned.

## Alternatives Considered

### Manage certificates within each environment

This would keep the certificate configuration close to its consuming ALB.

Rejected because destroying temporary EKS infrastructure could also destroy certificates, creating unnecessary reissuance and DNS validation work.

### Use one certificate for all environments

A single certificate could cover development, staging and production.

Rejected because separate certificates provide clearer environment ownership and reduce coupling between production and non-production certificate changes.

### Create a new Route 53 hosted zone

Rejected because an authoritative hosted zone already exists for `ammandevops.xyz`.

Creating another hosted zone could introduce unnecessary cost and DNS configuration confusion.

### Use email validation

Rejected because DNS validation is easier to automate through Terraform and Route 53.

### Manage certificates manually

Rejected because manually issued certificates would introduce configuration drift and make environment recovery less reproducible.

## Consequences

### Benefits

- Certificates survive EKS environment destruction and recreation.
- TLS certificate provisioning is automated through Terraform.
- Existing Route 53 infrastructure is reused.
- Production and non-production have separate certificate lifecycles.
- DNS validation records support ACM-managed certificate renewal.
- Certificate ARNs can be referenced explicitly in GitOps manifests.

### Trade-offs and Limitations

- The shared Terraform root must be maintained independently from environment infrastructure.
- Certificate ARN changes require updates to consuming Ingress manifests.
- DNS validation records must remain correctly configured for managed renewal.
- Certificates must exist in the AWS region used by their ALBs.
- ACM certificate issuance does not automatically create application DNS routing records.
- Certificate replacement must be coordinated with active ALB listeners to avoid disruption.

## Validation

The following steps have been completed:

1. Terraform configuration was added to the shared infrastructure root.
2. The existing Route 53 hosted zone was reused.
3. DNS validation records were created through Terraform.
4. Both non-production and production ACM certificates reached the `ISSUED` status.
5. Certificate ARNs were added to the relevant Kubernetes Ingress manifests.

The following validation remains pending:

1. Deploy the AWS Load Balancer Controller and application Ingress resources.
2. Confirm the ALBs successfully attach the correct ACM certificates.
3. Configure and verify application DNS routing.
4. Confirm HTTPS connections and HTTP-to-HTTPS redirects for all three environments.
5. Verify certificate hostname coverage and browser trust.