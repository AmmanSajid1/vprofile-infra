variable environment {
    description = "Deployment environment"
    type = string
}

variable vpc_id {
    description = "VPC ID for the RDS instance"
    type = string
}

variable private_db_subnet_ids {
    description = "List of private subnet IDs for the RDS instance"
    type = list(string)
}

variable db_instance_class {
    description = "Instance class for the RDS instance"
    type = string 
}

variable db_name {
    description = "Name of the RDS database"
    type = string
}

variable db_username {
    description = "Username for the RDS database"
    type = string
}

variable storage_size {
    description = "Storage size for the RDS database"
    type = number
}

variable multi_az {
    description = "Whether the RDS instance should be multi-AZ"
    type = bool
}

variable tags {
    description = "Tags to apply to the RDS instance"
    type = map(string)
}

variable "app_security_group_id" {
  description = "Security group ID allowed to access the RDS instance"
  type        = string
}

variable backup_retention_period {
    description = "Backup retention period for the RDS instance"
    type = number
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection for the RDS instance"
  type = bool
}

variable "skip_final_snapshot" {
  description = "Whether to skip creation of a final snapshot when the RDS instance is deleted"
  type        = bool
}