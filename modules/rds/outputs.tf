output "rds_address" {
  description = "DNS hostname of the RDS instance"
  value       = aws_db_instance.rds_instance.address
}

output "rds_port" {
  description = "Port used by the RDS instance"
  value       = aws_db_instance.rds_instance.port
}

output "rds_instance_identifier" {
  description = "Identifier of the RDS instance"
  value       = aws_db_instance.rds_instance.identifier
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the RDS master credentials"
  value       = aws_db_instance.rds_instance.master_user_secret[0].secret_arn
}