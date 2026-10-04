variable cluster_name {
    description = "Name of the EKS cluster"
    type = string
}

variable "cluster_admin_arn" {
  description = "ARN of the IAM principal to assume the platform admin role"
  type        = string
}

variable private_app_subnet_ids {
    description = "List of private subnet IDs where the EKS cluster nodes will be deployed"
    type = list(string)
}

variable node_instance_type {
    description = "instance type for EKS worker nodes to use"
    type = string
}

variable node_desired_capacity {
    description = "Desired number of EKS worker nodes"
    type = number

    validation {
      condition     = var.node_desired_capacity >= var.node_min_capacity && var.node_desired_capacity <= var.node_max_capacity
      error_message = "The desired number of EKS worker nodes must be between the minimum and maximum number of EKS worker nodes."
    }
}

variable node_max_capacity {
    description = "Maximum number of EKS worker nodes"
    type = number

    validation {
        condition     = var.node_max_capacity >= var.node_min_capacity
        error_message = "The maximum number of EKS worker nodes must be greater than or equal to the minimum number of EKS worker nodes."
    }

}

variable node_min_capacity {
    description = "Minimum number of EKS worker nodes"
    type = number
}

variable public_api_endpoint_access {
    description = "Whether the EKS cluster's public API endpoint is accessible"
    type = bool
}

variable private_api_endpoint_access {
    description = "Whether the EKS cluster's private API endpoint is accessible"
    type = bool
}

variable public_api_access_allowed_cidrs {
    description = "List of CIDR blocks allowed to access the EKS cluster's public API endpoint"
    type = list(string)
}

variable tags {
    description = "Tags to apply to the EKS cluster"
    type = map(string)
    default = {}
}

variable k8s_version {
    description = "Kubernetes version for the EKS cluster"
    type = string
    default = "1.35"
}