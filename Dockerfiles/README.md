# play-with-containers

Docker Compose infrastructure for the required microservices architecture:

- `inventory-database`: PostgreSQL database for movies, available only inside Docker on port `5432`.
- `billing-database`: PostgreSQL database for billing orders, available only inside Docker on port `5432`.
- `inventory-app`: FastAPI inventory service, available only inside Docker on port `8080`.
- `billing-app`: RabbitMQ consumer that stores billing orders in the billing database.
- `rabbit-queue`: RabbitMQ queue, available only inside Docker on port `5672`.
- `api-gateway-app`: public API gateway, exposed on host port `3000`.

All images are built locally from `Debian 12` or `Alpine 3.21` base images. The only host-exposed service is `api-gateway-app`.

## Prerequisites

- Docker
- Docker Compose

## Configuration

Create a `.env` file in the project root. It is ignored by Git and must contain the secrets and runtime configuration:

```env
INVENTORY_HOST=0.0.0.0
INVENTORY_PORT=8080
INVENTORY_POSTGRES_HOST=inventory-database
INVENTORY_POSTGRES_USER=inventory_user
INVENTORY_POSTGRES_PASSWORD=change-me
INVENTORY_POSTGRES_DB=inventory
INVENTORY_POSTGRES_PORT=5432

BILLING_POSTGRES_HOST=billing-database
BILLING_POSTGRES_USER=billing_user
BILLING_POSTGRES_PASSWORD=change-me
BILLING_POSTGRES_DB=billing
BILLING_POSTGRES_PORT=5432
BILLING_DATABASE_URL=unused

BILLING_RABBITMQ_HOST=rabbit-queue
BILLING_RABBITMQ_PORT=5672
BILLING_RABBITMQ_MANAGEMENT_PORT=15672
BILLING_RABBITMQ_USER=billing_user
BILLING_RABBITMQ_PASSWORD=change-me
BILLING_RABBITMQ_QUEUE=billing_orders

GATE_HOST=0.0.0.0
GATE_PORT=3000
GATE_INVENTORY_URL=http://inventory-app:8080
```

## Setup

Build and start all services:

```sh
docker-compose up --build
```

Run in the background:

```sh
docker-compose up --build -d
```

Stop and delete containers/networks:

```sh
docker-compose down
```

Delete containers, networks, and persistent volumes:

```sh
docker-compose down -v
```

## Usage

Add a movie through the gateway:

```sh
curl -X POST http://localhost:3000/api/movies/ \
  -H 'Content-Type: application/json' \
  -d '{"title":"A new movie","description":"Very short description"}'
```

List movies:

```sh
curl http://localhost:3000/api/movies/
```

Queue a billing order through the gateway:

```sh
curl -X POST http://localhost:3000/api/billing/ \
  -H 'Content-Type: application/json' \
  -d '{"user_id":"20","number_of_items":"99","total_amount":"250"}'
```

The billing endpoint publishes to RabbitMQ, so it can still return successfully while `billing-app` is stopped. When `billing-app` is running again, it consumes queued messages and stores them in `billing-database`.

## Management Checks

List containers:

```sh
docker ps
```

List volumes:

```sh
docker volume ls
```

Inspect restart policy:

```sh
docker inspect -f "{{ .HostConfig.RestartPolicy }}" api-gateway-app
```
