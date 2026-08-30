# Cloud-Design

Cloud-Design extends the tested Vagrant/K3s microservices deployment from the
previous `orchestrator` project. The local deployment is the executable part of
this repository. The AWS design is represented as Terraform and documentation,
but is not applied because this project intentionally has no AWS account.

## Requirements

The application consists of:

| Component | Kind | Port | Responsibility |
| --- | --- | ---: | --- |
| `inventory-db` | PostgreSQL StatefulSet | 5432 | Movie inventory data |
| `billing-db` | PostgreSQL StatefulSet | 5432 | Billing/order data |
| `rabbitmq` | Deployment | 5672 | Billing message queue |
| `inventory-app` | Deployment | 8080 | Inventory API |
| `billing-app` | StatefulSet | 8080 | Billing consumer/API |
| `api-gateway-app` | Deployment | 3000 | External API gateway |

The gateway is the only service exposed outside the cluster. Databases and
RabbitMQ are reached through internal Kubernetes Services.

## Local Prerequisites

- Vagrant
- VirtualBox
- `kubectl`
- Docker, if rebuilding images
- Access to the public Docker Hub images referenced by the manifests

## Local Setup

Create a local environment file and replace the example values:

```sh
cp .env.example .env.local
chmod 600 .env.local
```

Create the two-node K3s cluster:

```sh
./orchestrator.sh create
```

Create the Kubernetes Secret after the kubeconfig has been generated:

```sh
./Scripts/create-local-secret.sh
```

The same operation is available through the orchestrator wrapper:

```sh
./orchestrator.sh secret
```

Deploy or reconcile the workloads:

```sh
./orchestrator.sh deploy
./orchestrator.sh verify
```

Inspect the deployment:

```sh
./orchestrator.sh nodes
./orchestrator.sh pods
KUBECONFIG=.kube/config kubectl get svc,pvc,hpa
```

The gateway is available at `http://192.168.60.10:30000` while the cluster is
running. Example requests:

```sh
curl -X POST http://192.168.60.10:30000/api/movies/ \
  -H 'Content-Type: application/json' \
  -d '{"title":"A new movie","description":"Very short description"}'

curl http://192.168.60.10:30000/api/movies/

curl -X POST http://192.168.60.10:30000/api/billing/ \
  -H 'Content-Type: application/json' \
  -d '{"user_id":20,"number_of_items":2,"total_amount":25}'
```

To verify queue recovery, scale `billing-app` to zero, submit a billing
request, inspect the RabbitMQ queue, then restore the StatefulSet:

```sh
KUBECONFIG=.kube/config kubectl scale statefulset billing-app --replicas=0
KUBECONFIG=.kube/config kubectl scale statefulset billing-app --replicas=1
```

## Building Images

The `Dockerfiles/` directory is the complete build context. Build images from
that directory and update the image tags in `Manifests/` when using local
images:

```sh
cd Dockerfiles
docker build -f docker/postgres/Dockerfile -t cloud-design/inventory-db:dev .
docker build -f docker/postgres/Dockerfile -t cloud-design/billing-db:dev .
docker build -f docker/rabbit-queue/Dockerfile -t cloud-design/rabbitmq:dev .
docker build -f apps/inventory/Dockerfile -t cloud-design/inventory-app:dev .
docker build -f apps/billing/Dockerfile -t cloud-design/billing-app:dev .
docker build -f apps/gateway/Dockerfile -t cloud-design/api-gateway-app:dev .
```

The current manifests retain the previously tested public image names until a
local image-loading workflow is selected and verified.

## Verification

At minimum, collect evidence for:

- All nodes are Ready and all six services become available.
- Gateway inventory requests succeed.
- Billing requests reach RabbitMQ and are persisted by `billing-app`.
- PVCs remain bound and data survives a pod restart.
- Gateway and inventory HPAs have the required range of one to three replicas
  with a 60% CPU target.
- Stopping the billing consumer allows messages to queue and resuming it drains
  the queue.
- Application logs and pod events show no connectivity errors.

Recorded baseline results are in `docs/evidence/local-baseline.md`.

The audit commands are the local equivalents of the requested cloud evidence:

```sh
KUBECONFIG=.kube/config kubectl get nodes -o wide
KUBECONFIG=.kube/config kubectl get pods,svc,pvc,hpa
KUBECONFIG=.kube/config kubectl describe pod <pod-name>
KUBECONFIG=.kube/config kubectl logs <pod-name>
```

## Cleanup

```sh
./orchestrator.sh clean
```

This removes the local VMs and generated K3s state. It does not affect the
separate source repository at `/home/eb/scripts/reboot/devops/orchestrator`.

## Proposed AWS Architecture

`terraform/` contains a design-only AWS implementation. The intended mapping is
EKS or ECS for workloads, private subnets for databases and RabbitMQ, an
internet-facing load balancer for the gateway, IAM least-privilege roles,
encrypted storage, Cognito for public authentication, and CloudWatch for AWS
logs and metrics.

Terraform may be formatted and statically validated, but must not be applied:

```sh
terraform -chdir=terraform fmt -check
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
```

The AWS deployment, AWS CLI evidence, billing alerts, real cloud autoscaling,
and AWS monitoring cannot be verified without an AWS account. Those limitations
are intentional and must be stated during the audit rather than represented as
completed deployment work.

## Local Monitoring

After rebuilding the monitoring images and reconciling the application
manifests, install the local Prometheus/Grafana stack:

```sh
./Monitoring/install.sh
```

See `Monitoring/README.md` for port-forwarding, dashboard, and evidence
instructions.

## Design Notes

- Vagrant/K3s is retained because it is the previously tested local baseline.
- The old NFS-specific storage class was removed from database claims so the
  manifests use K3s's default local-path provisioner.
- Credentials are generated into a Kubernetes Secret from ignored local input;
  they are not committed to this repository.
- The local NodePort is a development substitute for an AWS load balancer, not
  an AWS security boundary.
- Production HTTPS, managed authentication, VPC isolation, encryption,
  vulnerability scanning, and AWS observability remain part of the proposed
  cloud design and are not claimed as locally implemented AWS features.
