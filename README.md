# Cloud Design

Infrastructure-as-code design for deploying the [01-edu orchestrator](https://github.com/01-edu/orchestrator) microservices application to AWS. The application is developed and verified locally first; Terraform describes the AWS environment that will later host it.

## Status

The Terraform root configuration is complete and validates locally. AWS resources have not yet been provisioned because this project is being developed without an AWS account.

| Area | Status |
| --- | --- |
| Local Kubernetes application | Assumed working from the supplied orchestrator project |
| Terraform provider and inputs | Complete |
| VPC and subnet routing | Defined; not provisioned |
| EKS and ECR | Planned |
| Kubernetes deployment to AWS | Planned |
| Monitoring, logging, autoscaling, and Cognito | Planned |

## Architecture

The initial AWS implementation preserves the supplied Kubernetes workload model. All six application components run in Amazon EKS. PostgreSQL and RabbitMQ use persistent volumes backed by Amazon EBS and remain private to the cluster.

```mermaid
flowchart TB
    Internet[Internet] --> ALB[Application Load Balancer]
    Cognito[Amazon Cognito] -. authenticates public requests .-> ALB

    subgraph VPC[AWS VPC: two Availability Zones]
        subgraph Public[Public subnets]
            ALB
        end

        subgraph Private[Private subnets]
            subgraph EKS[Amazon EKS]
                Gateway[api-gateway-app :3000]
                Inventory[inventory-app :8080]
                Billing[billing-app :8080]
                InventoryDB[(inventory PostgreSQL :5432)]
                BillingDB[(billing PostgreSQL :5432)]
                Queue[RabbitMQ :5672]
            end
        end
    end

    ALB --> Gateway
    Gateway --> Inventory
    Gateway --> Queue
    Inventory --> InventoryDB
    Billing --> BillingDB
    Billing <--> Queue
```

Only the Application Load Balancer accepts internet traffic. Kubernetes Services provide private communication between the gateway, applications, databases, and RabbitMQ. Databases and the queue have no public IP addresses or public load balancers.

## Application Components

| Component | Port | Responsibility |
| --- | --- | --- |
| `api-gateway-app` | 3000 | Public entry point; forwards inventory requests and publishes billing messages |
| `inventory-app` | 8080 | Inventory API; connects to `inventory-db` |
| `billing-app` | 8080 | Consumes billing messages; connects to `billing-db` |
| `inventory-db` | 5432 | PostgreSQL data store for inventory |
| `billing-db` | 5432 | PostgreSQL data store for billing |
| `billing-queue` | 5672 | RabbitMQ message broker for billing work |

The supplied manifests already define Horizontal Pod Autoscalers for `api-gateway-app` and `inventory-app`, with one to three replicas at a 60% CPU target. EKS metrics support will be configured before these autoscalers are used in AWS.

## Repository Layout

```text
docs/                  Project brief and audit requirements
terraform/             AWS infrastructure configuration
  versions.tf          Terraform and provider version constraints
  provider.tf          AWS provider and common resource tags
  variables.tf         Environment inputs and validation
  locals.tf            Naming convention and shared tags
  network.tf           VPC, subnets, internet gateway, NAT gateway, and routes
  outputs.tf           Network IDs for later infrastructure components
```

The reference application is currently cloned separately at `/home/eb/scripts/reboot/devops/orchestrator-cd`. Its Kubernetes manifests are the source model for the future EKS deployment.

## Prerequisites

For local validation:

- Terraform 1.15.x
- Internet access to download Terraform providers on first initialization

For local application testing:

- The orchestrator project's prerequisites: Vagrant, VirtualBox, Docker, and `kubectl`

For a future AWS deployment:

- AWS account and AWS CLI credentials
- An AWS CLI profile with permission to create the documented resources
- `kubectl`
- Docker and access to push application images to Amazon ECR

## Terraform Usage

Run Terraform commands from the `terraform/` directory.

```sh
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

The current configuration needs no AWS credentials because it defines no AWS resources. Later, use an uncommitted `terraform.tfvars` file to select a region, environment, and optional AWS CLI profile:

```hcl
aws_region  = "eu-west-3"
environment = "dev"
aws_profile = "cloud-design"
```

`terraform/*.tfvars`, state files, and Terraform's plugin directory are excluded from Git. The provider lock file is committed so collaborators use the same provider version.

## Design Decisions

### EKS

EKS is selected because the reference project is already expressed as Kubernetes manifests. This preserves Kubernetes services, deployments, StatefulSets, persistent volume claims, and horizontal autoscaling rather than translating the application into a different orchestration model.

### Stateful Workloads

For the initial implementation, both PostgreSQL databases and RabbitMQ remain Kubernetes StatefulSets in EKS with EBS-backed persistent volumes. This directly reflects the project requirements and limits the first AWS implementation to one orchestration model.

The documented production alternative is Amazon RDS for PostgreSQL and Amazon MQ for RabbitMQ. Managed services reduce operational work and can improve availability, backups, patching, and recovery, but require additional configuration and alter the supplied Kubernetes deployment.

### Networking

The VPC spans `eu-west-3a` and `eu-west-3b`, with a `/16` VPC CIDR. Public load-balancer subnets use `10.0.0.0/24` and `10.0.1.0/24`; private EKS subnets use `10.0.16.0/20` and `10.0.32.0/20`. These values are configurable Terraform inputs.

The public route table sends internet-bound traffic to an Internet Gateway. Both private subnets instead use one NAT gateway in the first public subnet, allowing private workloads to pull images and receive updates without accepting unsolicited inbound internet traffic. A single NAT gateway is an intentional development cost trade-off and a single-AZ failure point. A production environment should use a NAT gateway per Availability Zone or use VPC endpoints for supported AWS services.

### Security

- TLS will terminate at the ALB using AWS Certificate Manager.
- Cognito will provide managed authentication for the public API.
- Security groups will allow only required ingress between the load balancer and EKS workloads.
- Kubernetes Secrets will not be committed. AWS Secrets Manager integration is planned for the deployed environment.
- IAM roles for service accounts will give Kubernetes controllers narrowly scoped AWS access.
- Network policies will restrict pod-to-pod traffic to required application paths.

## Operations Plan

CloudWatch logging and metrics, Kubernetes readiness and liveness probes, EKS metrics, and the supplied application HPAs will provide the initial operational view. The final deployment will document dashboards, alert thresholds, log retention, load testing, and scaling results.

## Cost Management

EKS, load balancers, NAT gateways, EC2 worker nodes, EBS volumes, and data transfer can incur costs even at low traffic. Before applying this configuration to a real account:

- Configure an AWS Budget and billing alerts.
- Use a dedicated `dev` environment with minimal node and storage sizes.
- Review `terraform plan` before every apply.
- Destroy temporary environments with `terraform destroy` when finished.
- Remove unused container images, volumes, and load balancers.

## Roadmap

1. Create security groups, ECR repositories, and the EKS cluster.
2. Adapt the supplied Kubernetes manifests for AWS ingress, storage, secrets, and image locations.
3. Configure TLS, Cognito, logging, monitoring, and autoscaling.
4. Perform load, recovery, security, and cost validation on a real AWS account.
