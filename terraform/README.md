# AWS Design-Only Terraform

This directory describes the AWS target architecture for Cloud-Design. It is
intentionally not deployable in this environment because there is no AWS
account and no AWS subscription will be created.

The configuration defines a small production-shaped ECS Fargate deployment:
three public/private AZ pairs, one cost-conscious NAT Gateway, a public HTTPS
ALB with Cognito authentication, private ECS services, Cloud Map discovery,
immutable ECR repositories, Secrets Manager, encrypted Multi-AZ RDS databases,
a private Multi-AZ Amazon MQ RabbitMQ cluster, ECS CPU autoscaling, and
CloudWatch logs plus a gateway 5xx alarm.

The one NAT Gateway is a deliberate cost trade-off. It keeps the design simple
but leaves private-task egress dependent on one AZ. Multi-AZ RDS and Amazon MQ
are retained because they protect business data and queued messages.

The ECS task definitions assume the application supports TLS for Amazon MQ
RabbitMQ (`BILLING_RABBITMQ_TLS=true`, port `5671`). The local K3s deployment
continues to use plain AMQP and is not changed by this design-only Terraform.

Safe local checks:

```sh
terraform -chdir=terraform fmt -check
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
```

`terraform validate` does not contact AWS, but `init` may download the provider
plugin. Never run `terraform plan` or `terraform apply` with real credentials
from this project. The database and broker credentials are required variables
for any future cloud-enabled plan and must never be committed.

Before a real deployment, an AWS-enabled operator must push the three immutable
application images to ECR and provide a Route 53 hosted zone and domain name.
The ACM certificate is DNS-validated by Terraform. The Secrets Manager secret
values are sensitive and would be stored in Terraform state, so a real setup
must use encrypted remote state in S3 with locking.
