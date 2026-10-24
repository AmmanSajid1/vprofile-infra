resource "aws_secretsmanager_secret" "mysql_app" {
  name        = "vprofile/nonprod/mysql-app"
  description = "MySQL application credentials for vProfile nonprod"

  lifecycle {
    prevent_destroy = true
  }

  recovery_window_in_days = 7

  tags = {
    Environment = "nonprod"
    Purpose     = "application-database-credentials"
  }
}

resource "aws_secretsmanager_secret" "mysql_migrator" {
  name        = "vprofile/nonprod/mysql-migrator"
  description = "Flyway migration credentials for vProfile nonprod"

  lifecycle {
    prevent_destroy = true
  }

  recovery_window_in_days = 7

  tags = {
    Environment = "nonprod"
    Purpose     = "database-migrations"
  }
}

resource "aws_secretsmanager_secret" "staging_mysql_app" {
  name        = "vprofile/staging/mysql-app"
  description = "MySQL application credentials for vProfile staging"

  lifecycle {
    prevent_destroy = true
  }

  recovery_window_in_days = 7

  tags = {
    Environment = "staging"
    Purpose     = "application-database-credentials"
  }
}

resource "aws_secretsmanager_secret" "staging_mysql_migrator" {
  name        = "vprofile/staging/mysql-migrator"
  description = "Flyway migration credentials for vProfile staging"

  lifecycle {
    prevent_destroy = true
  }

  recovery_window_in_days = 7

  tags = {
    Environment = "staging"
    Purpose     = "database-migrations"
  }
}