variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "vprofile-infra"
}

variable "github_org" {
  description = "The GitHub organization for the OIDC provider"
  type        = string
  default     = "AmmanSajid1"
}

variable "github_repo" {
  description = "The GitHub repository for the OIDC provider"
  type        = string
  default     = "vprofile-app"
}

variable "ecr_repo_name" {
  description = "The name of the ECR repository"
  type        = string
  default     = "vprofile-app"
}

# ACM certificate configuration

variable "hosted_zone_name" {
  description = "Existing public Route 53 hosted zone"
  type        = string
  default     = "ammandevops.xyz"
}

variable "domain_map_env" {
  description = "Certificate domain names per environment"
  type        = map(list(string))

  default = {
    nonprod = [
      "dev.ammandevops.xyz",
      "staging.ammandevops.xyz"
    ]

    prod = [
      "app.ammandevops.xyz"
    ]
  }

  validation {
    condition = alltrue([
      for domains in values(var.domain_map_env) : length(domains) > 0
    ])
    error_message = "Every environment must have at least one domain."
  }
}
