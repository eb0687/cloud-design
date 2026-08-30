resource "aws_db_subnet_group" "main" {
  name       = "${local.name}-databases"
  subnet_ids = aws_subnet.private[*].id

  tags = { Name = "${local.name}-databases" }
}

resource "aws_db_instance" "inventory" {
  identifier              = "${local.name}-inventory-db"
  engine                  = "postgres"
  engine_version          = "16"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  db_name                 = "movies"
  username                = var.database_username
  password                = var.database_password
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.inventory_database.id]
  publicly_accessible     = false
  storage_encrypted       = true
  multi_az                = true
  backup_retention_period = 7
  deletion_protection     = true
  skip_final_snapshot     = false
}

resource "aws_db_instance" "billing" {
  identifier              = "${local.name}-billing-db"
  engine                  = "postgres"
  engine_version          = "16"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  db_name                 = "orders"
  username                = var.database_username
  password                = var.database_password
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.billing_database.id]
  publicly_accessible     = false
  storage_encrypted       = true
  multi_az                = true
  backup_retention_period = 7
  deletion_protection     = true
  skip_final_snapshot     = false
}

resource "aws_mq_broker" "rabbitmq" {
  broker_name                = "${local.name}-rabbitmq"
  engine_type                = "RabbitMQ"
  engine_version             = "3.13"
  host_instance_type         = "mq.t3.micro"
  publicly_accessible        = false
  deployment_mode            = "CLUSTER_MULTI_AZ"
  auto_minor_version_upgrade = true
  subnet_ids                 = aws_subnet.private
  security_groups            = [aws_security_group.rabbitmq.id]

  user {
    username = var.mq_username
    password = var.mq_password
  }
}
