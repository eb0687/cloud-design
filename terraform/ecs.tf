resource "aws_ecs_cluster" "main" {
  name = local.name
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.name}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_secrets" {
  name = "${local.name}-ecs-task-secrets"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue"]
      Resource = [
        aws_secretsmanager_secret.inventory_database.arn,
        aws_secretsmanager_secret.billing_database.arn,
        aws_secretsmanager_secret.rabbitmq.arn,
      ]
    }]
  })
}

resource "aws_service_discovery_private_dns_namespace" "main" {
  name = "${local.name}.internal"
  vpc  = aws_vpc.main.id
}

resource "aws_service_discovery_service" "inventory" {
  name = "inventory-app"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
}

resource "aws_lb" "gateway" {
  name               = "${local.name}-gateway"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "gateway" {
  name        = "${local.name}-gateway"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path = "/openapi.json"
  }
}

resource "aws_ecs_task_definition" "gateway" {
  family                   = "${local.name}-gateway"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name      = "api-gateway-app"
    image     = "${aws_ecr_repository.service["api-gateway-app"].repository_url}:${var.gateway_image_tag}"
    essential = true

    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]

    environment = [
      { name = "GATE_HOST", value = "0.0.0.0" },
      { name = "GATE_PORT", value = "3000" },
      { name = "GATE_INVENTORY_URL", value = "http://inventory-app.${local.name}.internal:8080" },
      { name = "BILLING_RABBITMQ_HOST", value = trimsuffix(trimprefix(aws_mq_broker.rabbitmq.instances[0].endpoints[0], "amqps://"), ":5671") },
      { name = "BILLING_RABBITMQ_PORT", value = "5671" },
      { name = "BILLING_RABBITMQ_MANAGEMENT_PORT", value = "443" },
      { name = "BILLING_RABBITMQ_TLS", value = "true" },
      { name = "BILLING_RABBITMQ_QUEUE", value = "billing_queue" },
    ]

    secrets = [
      { name = "BILLING_RABBITMQ_USER", valueFrom = "${aws_secretsmanager_secret.rabbitmq.arn}:username::" },
      { name = "BILLING_RABBITMQ_PASSWORD", valueFrom = "${aws_secretsmanager_secret.rabbitmq.arn}:password::" },
    ]

    healthCheck = {
      command     = ["CMD-SHELL", "python3 -c \"import urllib.request; urllib.request.urlopen('http://localhost:3000/openapi.json')\""]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 30
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.application.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "gateway"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "inventory" {
  family                   = "${local.name}-inventory"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name         = "inventory-app"
    image        = "${aws_ecr_repository.service["inventory-app"].repository_url}:${var.inventory_image_tag}"
    essential    = true
    portMappings = [{ containerPort = 8080, protocol = "tcp" }]
    environment = [
      { name = "INVENTORY_HOST", value = "0.0.0.0" },
      { name = "INVENTORY_PORT", value = "8080" },
      { name = "INVENTORY_POSTGRES_HOST", value = aws_db_instance.inventory.address },
      { name = "INVENTORY_POSTGRES_DB", value = "movies" },
      { name = "INVENTORY_POSTGRES_PORT", value = "5432" },
    ]
    secrets = [
      { name = "INVENTORY_POSTGRES_USER", valueFrom = "${aws_secretsmanager_secret.inventory_database.arn}:username::" },
      { name = "INVENTORY_POSTGRES_PASSWORD", valueFrom = "${aws_secretsmanager_secret.inventory_database.arn}:password::" },
    ]

    healthCheck = {
      command     = ["CMD-SHELL", "python3 -c \"import urllib.request; urllib.request.urlopen('http://localhost:8080/')\""]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 30
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.application.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "inventory"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "billing" {
  family                   = "${local.name}-billing"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name         = "billing-app"
    image        = "${aws_ecr_repository.service["billing-app"].repository_url}:${var.billing_image_tag}"
    essential    = true
    portMappings = [{ containerPort = 8080, protocol = "tcp" }]
    environment = [
      { name = "BILLING_POSTGRES_HOST", value = aws_db_instance.billing.address },
      { name = "BILLING_POSTGRES_DB", value = "orders" },
      { name = "BILLING_POSTGRES_PORT", value = "5432" },
      { name = "BILLING_RABBITMQ_HOST", value = trimsuffix(trimprefix(aws_mq_broker.rabbitmq.instances[0].endpoints[0], "amqps://"), ":5671") },
      { name = "BILLING_RABBITMQ_PORT", value = "5671" },
      { name = "BILLING_RABBITMQ_MANAGEMENT_PORT", value = "443" },
      { name = "BILLING_RABBITMQ_TLS", value = "true" },
      { name = "BILLING_RABBITMQ_QUEUE", value = "billing_queue" },
    ]
    secrets = [
      { name = "BILLING_POSTGRES_USER", valueFrom = "${aws_secretsmanager_secret.billing_database.arn}:username::" },
      { name = "BILLING_POSTGRES_PASSWORD", valueFrom = "${aws_secretsmanager_secret.billing_database.arn}:password::" },
      { name = "BILLING_RABBITMQ_USER", valueFrom = "${aws_secretsmanager_secret.rabbitmq.arn}:username::" },
      { name = "BILLING_RABBITMQ_PASSWORD", valueFrom = "${aws_secretsmanager_secret.rabbitmq.arn}:password::" },
    ]

    healthCheck = {
      command     = ["CMD-SHELL", "python3 -c \"import urllib.request; urllib.request.urlopen('http://localhost:8080/')\""]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 30
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.application.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "billing"
      }
    }
  }])
}

resource "aws_ecs_service" "gateway" {
  name            = "${local.name}-gateway"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.gateway.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.gateway_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.gateway.arn
    container_name   = "api-gateway-app"
    container_port   = 3000
  }
}

resource "aws_ecs_service" "inventory" {
  name            = "${local.name}-inventory"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.inventory.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.inventory_tasks.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.inventory.arn
  }
}

resource "aws_ecs_service" "billing" {
  name            = "${local.name}-billing"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.billing.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.billing_tasks.id]
    assign_public_ip = false
  }
}
