resource "aws_security_group" "database_sg" {
  name        = "${var.rds_name}-rds"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.office_ip]
    description = "SSH from office"
  }

  ingress {
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.rds_name}-rds"
  }
}

data "hcp_vault_secrets_app" "example" {
  app_name = "gbaccesscontrol-production"
}

resource "aws_db_instance" "db_instance" {
  identifier                  = var.rds_name
  db_name                     = var.initial_db_name
  engine                      = "postgres"
  engine_version              = "15.3"
  instance_class              = var.instance_class
  allocated_storage           = 20
  max_allocated_storage       = 50
  publicly_accessible         = true
  backup_retention_period     = 3
  delete_automated_backups    = true
  deletion_protection         = false
  multi_az                    = false
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  skip_final_snapshot         = true
  apply_immediately           = true
  username                    = "gbaccesscontrol"
  password                    = data.hcp_vault_secrets_app.example.secrets.POSTGRES_PASSWORD
  vpc_security_group_ids      = [
    aws_security_group.database_sg.id
  ]
}


