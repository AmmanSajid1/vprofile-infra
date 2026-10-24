output "rds_address" {
  description = "DNS hostname of the RDS instance"
  value       = module.rds.rds_address
}

output "rds_port" {
  description = "Port used by the RDS instance"
  value       = module.rds.rds_port
}

output "rds_instance_identifier" {
  description = "Identifier of the RDS instance"
  value       = module.rds.rds_instance_identifier
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the RDS master credentials"
  value       = module.rds.master_user_secret_arn
}

output "platform_admin_role_arn" {
  description = "ARN of the platform administrator IAM role"
  value       = module.eks.platform_admin_role_arn
}

