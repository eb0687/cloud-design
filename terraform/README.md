# AWS Design-Only Terraform

This directory describes the AWS target architecture for Cloud-Design. It is
intentionally not deployable in this environment because there is no AWS
account and no AWS subscription will be created.

The configuration defines the target region, routable public/private subnet
layout, gateway security boundary, private service boundary, ECS and IAM
scaffolding, immutable ECR repositories, encrypted private RDS databases,
private Amazon MQ RabbitMQ, Cognito, an HTTPS application load balancer, and a
CloudWatch log group. ECS services and autoscaling policies remain the next
wiring layer because the local project has no AWS credentials or image registry.

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
