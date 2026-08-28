# Cloud-Design TODO

This checklist is based on `docs/PROJECT.md` and `docs/AUDIT.md`.

## Constraint: no AWS account

- [x] Do not create an AWS account, subscribe to AWS, or deploy billable AWS resources.
- [ ] Build and test the application locally with Docker and a local Kubernetes cluster (`kind`, `minikube`, or equivalent).
- [x] Keep AWS Terraform, deployment manifests, and AWS architecture documentation as reviewed, non-applied deliverables.
- [x] Mark every AWS-only item as `blocked: requires AWS credentials` rather than pretending it was deployed.
- [x] Document the local substitute and the AWS equivalent for each cloud concern.

## Repository and source code

- [x] Import or implement the six required services:
  - [ ] Inventory PostgreSQL database on port `5432`.
  - [ ] Billing PostgreSQL database on port `5432`.
  - [ ] Inventory app on port `8080`.
  - [ ] Billing app on port `8080`.
  - [ ] RabbitMQ message broker.
  - [ ] API gateway on port `3000`.
- [ ] Verify the inventory app connects only to the inventory database.
- [ ] Verify the billing app connects only to the billing database and consumes RabbitMQ messages.
- [ ] Verify the API gateway forwards requests to the application services.
- [x] Add configuration through environment variables or secret references; do not commit credentials.
- [ ] Add health and readiness endpoints for every application service.
- [ ] Add automated tests for service behavior, database connectivity, gateway routing, and message consumption.

## Containerization

- [x] Add one Dockerfile per service where appropriate.
- [x] Use multi-stage builds, minimal runtime images, pinned dependencies, and non-root users where supported.
- [x] Add `.dockerignore` files and ensure build contexts do not contain secrets or unnecessary files.
- [ ] Build every image locally and record image sizes and build commands.
- [ ] Run containers with resource limits and health checks.
- [ ] Add a local `docker compose` stack for the complete application and its dependencies.
- [ ] Confirm the stack starts from a clean checkout and services can communicate by service name.

## Local orchestration and deployment

- [ ] Choose and document `kind`, `minikube`, or another local Kubernetes runtime.
- [x] Create Kubernetes manifests or Helm configuration for deployments, services, config, and generated secrets.
- [ ] Deploy the complete stack locally and verify it survives an individual pod restart.
- [x] Expose only the API gateway externally; keep databases and RabbitMQ internal to the cluster.
- [ ] Add local ingress or load-balancing configuration and verify traffic reaches healthy replicas.
- [x] Document the AWS mapping without applying it: Kubernetes/ECS, load balancer, VPC, IAM, RDS, RabbitMQ, and Cognito equivalents.

## Terraform and infrastructure design

- [x] Create a Terraform module/layout for the proposed AWS architecture.
- [x] Define VPC, public/private subnets, routing, security groups, IAM roles, compute/orchestration scaffolding, storage, load balancing, and observability resources.
- [x] Ensure databases and other private resources have no public ingress.
- [x] Add variables, outputs, validation, tagging, and safe defaults.
- [x] Run `terraform fmt` and `terraform validate` locally.
- [ ] Review `terraform plan` configuration if possible without credentials; do not run `terraform apply`.
- [x] Add a clear `AWS deployment blocked` note and list the credentials/account prerequisites an AWS user would need.

## Security

- [x] Remove hard-coded passwords, tokens, and connection strings from source, manifests, and examples.
- [x] Restrict database access to the relevant application and private network only.
- [x] Restrict RabbitMQ access to authorized services only.
- [x] Use TLS/HTTPS in the documented production design; explicitly document local HTTP as a limitation.
- [ ] Define managed authentication for public API access using Cognito in the AWS design and a local equivalent for testing.
- [ ] Run dependency, image, and manifest vulnerability scans with locally available tools.
- [ ] Document least-privilege IAM, encryption at rest/in transit, secret rotation, and network boundaries.

## Monitoring, logging, and resilience

- [ ] Emit structured application logs to stdout/stderr with request and correlation identifiers.
- [ ] Add application metrics and expose them for a local Prometheus deployment.
- [ ] Add local Prometheus and Grafana configuration with useful service, error, latency, and resource dashboards.
- [x] Document the AWS CloudWatch/Prometheus/Grafana/ELK equivalents without claiming AWS execution.
- [ ] Add alert rules for failed health checks, elevated errors, latency, queue depth, and resource exhaustion.
- [ ] Define replicas, readiness probes, liveness probes, and resource requests/limits.
- [ ] Add local autoscaling configuration where supported and test it with repeatable load generation.
- [ ] Test service failure, pod restart, database unavailability, and broker unavailability; queued-message recovery is recorded in `docs/evidence/local-baseline.md`.
- [ ] Record results, limitations, and which availability claims remain unverified without AWS.

## Architecture and cost analysis

- [x] Produce a clear architecture diagram for the local implementation.
- [x] Produce a separate proposed AWS architecture diagram showing public/private boundaries and traffic flow.
- [ ] Explain scalability, availability, security, cost-effectiveness, and simplicity decisions.
- [ ] Compare the cost and operational trade-offs of ECS versus EKS, managed versus self-hosted databases, and managed versus self-hosted RabbitMQ.
- [ ] State that AWS pricing, billing alerts, and real AWS autoscaling cannot be validated without an AWS account.
- [x] Include a cleanup procedure for local containers, images, volumes, and Kubernetes resources.

## README and audit evidence

- [x] Create the required root `README.md` with prerequisites, setup, configuration, usage, tests, troubleshooting, and cleanup.
- [x] Include both architecture diagrams and a component/port/dependency table.
- [ ] Document exact Docker, Kubernetes, and Terraform commands used for local verification.
- [ ] Include command output or screenshots for `docker ps`, Kubernetes status/logs, health checks, and load tests.
- [ ] Include Terraform formatting and validation evidence; explicitly note that AWS apply and cloud verification are blocked.
- [ ] Add a requirements-to-evidence checklist covering every item in `docs/AUDIT.md`.
- [x] Document known limitations caused by not having AWS access.
- [x] Add source code, deployment scripts, Dockerfiles, Kubernetes configuration, and Terraform configuration to the repository.

## Role-play preparation

- [ ] Prepare concise answers to every stakeholder question in `docs/AUDIT.md`, including cloud benefits, architecture, cost, security, observability, scaling, Docker optimization, challenges, alternatives, and portability.
- [ ] Be able to explain which claims are demonstrated locally and which are proposed AWS designs.
- [ ] Justify the choice of local substitutes and explain how the design would be deployed by an AWS-enabled operator.
- [ ] Practice a short architecture walkthrough from public request to gateway, services, databases, and RabbitMQ.
- [ ] Practice explaining failure handling, security boundaries, and the most important trade-offs.

## Optional bonus

- [ ] Add an API gateway authentication flow using a local identity provider.
- [ ] Add a local CDN/cache demonstration.
- [ ] Add chaos/failure tests and richer alerting.
- [ ] Compare the local design with a cloud-neutral deployment path.
