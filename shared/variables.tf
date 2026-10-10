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