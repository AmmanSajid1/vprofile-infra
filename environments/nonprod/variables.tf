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

variable "environment" {
  type = string
}

# VPC Configuration
variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_app_subnet_cidrs" {
  type = list(string)
}

variable "private_db_subnet_cidrs" {
  type = list(string)
}

variable "nat_gateway_count" {
  type = number
}


# EKS Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_admin_arn" {
  description = "ARN of the IAM principal to assume the platform admin role"
  type        = string
}

variable "node_instance_type" {
  description = "instance type for EKS worker nodes to use"
  type        = string
}

variable "node_desired_capacity" {
  description = "Desired number of EKS worker nodes"
  type        = number

  validation {
    condition     = var.node_desired_capacity >= var.node_min_capacity && var.node_desired_capacity <= var.node_max_capacity
    error_message = "The desired number of EKS worker nodes must be between the minimum and maximum number of EKS worker nodes."
  }
}

variable "node_max_capacity" {
  description = "Maximum number of EKS worker nodes"
  type        = number

  validation {
    condition     = var.node_max_capacity >= var.node_min_capacity
    error_message = "The maximum number of EKS worker nodes must be greater than or equal to the minimum number of EKS worker nodes."
  }

}

variable "node_min_capacity" {
  description = "Minimum number of EKS worker nodes"
  type        = number
}

variable "public_api_endpoint_access" {
  description = "Whether the EKS cluster's public API endpoint is accessible"
  type        = bool
}

variable "private_api_endpoint_access" {
  description = "Whether the EKS cluster's private API endpoint is accessible"
  type        = bool
}

variable "public_api_access_allowed_cidrs" {
  description = "List of CIDR blocks allowed to access the EKS cluster's public API endpoint"
  type        = list(string)
}


variable "k8s_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.35"
}

# RDS configuration
variable "backup_retention_period" {
  description = "Backup retention period for the RDS instance"
  type        = number
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection for the RDS instance"
  type        = bool
}

variable "skip_final_snapshot" {
  description = "Whether to skip creation of a final snapshot when the RDS instance is deleted"
  type        = bool
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
}

variable "db_name" {
  description = "Name of the RDS database"
  type        = string
}

variable "db_username" {
  description = "Username for the RDS database"
  type        = string
}

variable "storage_size" {
  description = "Storage size for the RDS database"
  type        = number
}

variable "multi_az" {
  description = "Whether the RDS instance should be multi-AZ"
  type        = bool
}