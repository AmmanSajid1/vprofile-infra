resource "aws_db_subnet_group" "rds_subnet_group" {
    name = "vprofile-${var.environment}-rds-subnet-group"
    subnet_ids = var.private_db_subnet_ids

    tags = merge(
        var.tags,
        {
            "Name" = "vprofile-${var.environment}-rds-subnet-group"
        }
    )

}

resource "aws_security_group" "rds_sg" {
    name = "vprofile-${var.environment}-rds-sg"
    description = "Security group for the RDS instance"
    vpc_id = var.vpc_id

    tags = merge(
        var.tags,
        {
            "Name" = "vprofile-${var.environment}-rds-sg"
        }
    )
}

resource "aws_vpc_security_group_ingress_rule" "rds_sg_ingress" {
    security_group_id = aws_security_group.rds_sg.id
    from_port = 3306
    to_port = 3306
    ip_protocol = "tcp"
    referenced_security_group_id = var.app_security_group_id
}

resource "aws_db_instance" "rds_instance" {
  allocated_storage    = var.storage_size
  db_name              = var.db_name
  identifier = "vprofile-${var.environment}-mysql"
  engine               = "mysql"
  engine_version       = "8.4"
  instance_class       = var.db_instance_class
  storage_type = "gp3"
  manage_master_user_password = true
  username             = var.db_username
  parameter_group_name = "default.mysql8.4"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  multi_az = var.multi_az
  storage_encrypted = true
  skip_final_snapshot  = var.skip_final_snapshot
  publicly_accessible = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  deletion_protection = var.deletion_protection
  backup_retention_period = var.backup_retention_period

  tags = merge(
    var.tags,
    {
        "Name" = "vprofile-${var.environment}-rds-instance"
    }
  )
}



