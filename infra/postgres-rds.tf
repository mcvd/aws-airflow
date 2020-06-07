
// IAM resources
data "aws_iam_policy_document" "enhanced_monitoring" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "random_password" "password" {
  length = 16
  special = false
}

//resource "aws_iam_role" "enhanced_monitoring" {
//  name               = "rds${var.ENV}EnhancedMonitoringRole"
//  assume_role_policy = data.aws_iam_policy_document.enhanced_monitoring.json
//}
//
//resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
//  role       = aws_iam_role.enhanced_monitoring.name
//  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
//}

// Defining an DB parameter group here, this is how AWS folks
// want us to tune pg_hba.conf
resource "aws_db_parameter_group" "postgresql" {
  name   = "${var.TAG}-postgres-rds"
  family = "postgres11"

  parameter {
    name  = "application_name"
    value = var.TAG
  }
  tags = {
    Name = var.TAG
  }
}




// Setting realtively a lot hardcoded config values here
// See DOCs https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html
resource "aws_db_instance" "postgresql" {
  allocated_storage               = "20" // The amount of storage (in gibibytes) to allocate for the DB instance.
  engine                          = "postgres"
  engine_version                  = "11"
  identifier                      = "${var.ENV}-${var.TAG}-rds-instance"
  // DBInstanceIdentifier            = var.database_identifier
  // -
  //snapshot_identifier             = "${var.TAG}-rds-instance-snapshot"
  // An existing dump/snapshot pointer
  // https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html
  instance_class                  = "db.t2.medium"
  storage_type                    = "gp2"
  // iops for OLTP workloads
  // iops                            = var.iops
  name                            = "airflow"
  password                        = random_password.password.result
  username                        = "airflow"
  backup_retention_period         = 14 // Two Weeks
  // No Overlaps in _windows
  backup_window                   = "02:30-03:30" // Number of days to keep database backups
  maintenance_window              = "sun:01:00-sun:02:00" // 60 minute time window to reserve for maintenance
  auto_minor_version_upgrade      = true // Indicates that minor version patches are applied automatically

  // final_snapshot_identifier       = var.final_snapshot_identifier
  // skip_final_snapshot             = var.skip_final_snapshot
  // copy_tags_to_snapshot           = var.copy_tags_to_snapshot

  multi_az                        = false // Specifies if the RDS instance is multi-AZ, not needed for
  port                            = "5432" // Postgres default
  vpc_security_group_ids          = [aws_security_group.postgres.id]
  db_subnet_group_name            = aws_db_subnet_group.postgres.name
  parameter_group_name            = aws_db_parameter_group.postgresql.name
  storage_encrypted               = true // Why not
//  monitoring_interval             = var.monitoring_interval
//  monitoring_role_arn             = var.monitoring_interval > 0 ? aws_iam_role.enhanced_monitoring.arn : ""
  deletion_protection             = false // Default is false, to be enables for OLTP app like workload
  // Omiting logs to CloudWatch for NOw
  //  enabled_cloudwatch_logs_exports = var.cloudwatch_logs_exports

  // Our RDS dependencies
  depends_on = [aws_db_parameter_group.postgresql, aws_db_subnet_group.postgres, aws_security_group.postgres]
  tags = {
    Name = var.TAG,
    Environment = var.ENV
  }
}