# Module: Aurora
# Author: Ivan Yu
# Maintainer: Ivan Yu
# Last Update: 2020-01-13

# Variables
variable project {
  type = string
  description = "The Project Name. Eg: ug or sgp."
}
variable env {
  type = string
  description = "The Environment Name. Eg: dev or prod"
}
variable aurora_name {
  type = string
  description = "The Name of Aurora."
}
variable instance_type {
  type = string
  description = "The Instance Type of Aurora."
}
variable db_name {
  type = string
  description = "The Initial DB Name."
}
variable db_username {
  type = string
  description = "The DB Username of Root."
}
variable db_password {
  type = string
  description = "The DB Password of Root."
}
variable db_sg {
  type = string
  description = "The Security Group of DB."
}
variable basic_db_sg {
  type = string
  description = "The Basic Security Group of DB."
}
variable db_subnet {
  type = string
  description = "The Subnet of DB."
}
variable "aws_az" {
  type = "list"
  description = "AZ"
}

# Resources
resource "aws_rds_cluster_parameter_group" "cluster_pg" {

  name        = "${var.project}-${var.env}-${var.aurora_name}-cluster-pg"
  family      = "aurora-mysql5.7"
  description = "${var.aurora_name} cluster parameter group"

  parameter {
    name  = "binlog_format"
    value = "ROW"
    apply_method = "pending-reboot"
  }
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }
  parameter {
    name  = "server_audit_logging"
    value = 1
  }
  parameter {
    name  = "server_audit_events"
    value = "CONNECT,QUERY"
  }
  parameter {
    name  = "server_audit_excl_users"
    value = "rdsadmin"
  }
  parameter {
    name = "lower_case_table_names"
    value = 1
    apply_method = "pending-reboot"
  }
  tags = {
      Name = "${var.project}-${var.env}-${var.aurora_name}-cluster-pg"
  }
}
resource "aws_db_parameter_group" "instance_pg" {

  name   = "${var.project}-${var.env}-${var.aurora_name}-instance-pg"
  family = "aurora-mysql5.7"
  description = "${var.aurora_name} instance parameter group"
   
  parameter {
    name  = "log_bin_trust_function_creators"
    value = 1
  }
  parameter {
    name  = "long_query_time"
    value = 20
  }
  parameter {
    name  = "max_allowed_packet"
    value = 20971520
  }
  parameter {
    name  = "max_execution_time"
    value = 3600000
  }
  parameter {
    name  = "performance_schema"
    value = 1
    apply_method = "pending-reboot"
  }
  parameter {
    name = "slow_query_log"
    value = 1
  } 
  tags = {
      Name = "${var.project}-${var.env}-${var.aurora_name}-instance-pg"
  }
}
resource "aws_rds_cluster" "cluster" {

  cluster_identifier      = "${var.project}-${var.env}-${var.aurora_name}-db"
  engine                  = "aurora-mysql"
  availability_zones      = "${var.aws_az}"
  database_name           = "${var.db_name}"
  master_username         = "${var.db_username}"
  master_password         = "${var.db_password}"
  backup_retention_period = 5
  port = 3306
  vpc_security_group_ids  = ["${var.db_sg}","${var.basic_db_sg}"]
  storage_encrypted       = true
  db_subnet_group_name    = "${var.db_subnet}"
  db_cluster_parameter_group_name = "${aws_rds_cluster_parameter_group.cluster_pg.id}"
  enabled_cloudwatch_logs_exports = ["audit"]
  skip_final_snapshot = true
  tags = {
      Name = "${var.project}-${var.env}-${var.aurora_name}-cluster",
      env = "${var.env}",
      project = "web backend"
  }
}
resource "aws_rds_cluster_instance" "instances_master" {

  engine                  = "aurora-mysql"
  promotion_tier     = 0
  count              = 1
  identifier         = "${var.project}-${var.env}-${var.aurora_name}-db-0"
  cluster_identifier = "${aws_rds_cluster.cluster.id}"
  instance_class     = "${var.instance_type}"
  db_subnet_group_name = "${var.db_subnet}"
  db_parameter_group_name = "${aws_db_parameter_group.instance_pg.id}"
  auto_minor_version_upgrade = false

  tags = {
      Name = "${var.project}-${var.env}-${var.aurora_name}-instance",
      env = "${var.env}",
      project = "web backend"
  }
}
resource "aws_rds_cluster_instance" "instances_reader" {

  engine                  = "aurora-mysql"
  promotion_tier     = 1
  count              = "${var.replica_number}"
  identifier         = "${var.project}-${var.env}-${var.aurora_name}-db-${count.index+1}"
  cluster_identifier = "${aws_rds_cluster.cluster.id}"
  instance_class     = "${var.instance_type}"
  db_subnet_group_name = "${var.db_subnet}"
  db_parameter_group_name = "${aws_db_parameter_group.instance_pg.id}"
  auto_minor_version_upgrade = false
  
  tags = {
      Name = "${var.project}-${var.env}-${var.aurora_name}-instance",
      env = "${var.env}",
      project = "web backend"
  }
  depends_on = ["aws_rds_cluster_instance.instances_master"]
}