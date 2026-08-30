resource "aws_secretsmanager_secret" "inventory_database" {
  name = "${local.name}/inventory-database"
}

resource "aws_secretsmanager_secret_version" "inventory_database" {
  secret_id = aws_secretsmanager_secret.inventory_database.id
  secret_string = jsonencode({
    username = var.database_username
    password = var.database_password
  })
}

resource "aws_secretsmanager_secret" "billing_database" {
  name = "${local.name}/billing-database"
}

resource "aws_secretsmanager_secret_version" "billing_database" {
  secret_id = aws_secretsmanager_secret.billing_database.id
  secret_string = jsonencode({
    username = var.database_username
    password = var.database_password
  })
}

resource "aws_secretsmanager_secret" "rabbitmq" {
  name = "${local.name}/rabbitmq"
}

resource "aws_secretsmanager_secret_version" "rabbitmq" {
  secret_id = aws_secretsmanager_secret.rabbitmq.id
  secret_string = jsonencode({
    username = var.mq_username
    password = var.mq_password
  })
}
