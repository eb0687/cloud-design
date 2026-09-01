# Cloud-Design

Cloud-Design extends the tested Vagrant/K3s microservices deployment from the
previous `orchestrator` project. It can run locally on K3s or on the minimal
AWS EKS foundation defined in `terraform/`.

## Requirements

The application consists of:

| Component         | Kind                   | Port | Responsibility        |
| ----------------- | ---------------------- | ---: | --------------------- |
| `inventory-db`    | PostgreSQL StatefulSet | 5432 | Movie inventory data  |
| `billing-db`      | PostgreSQL StatefulSet | 5432 | Billing/order data    |
| `rabbitmq`        | Deployment             | 5672 | Billing message queue |
| `inventory-app`   | Deployment             | 8080 | Inventory API         |
| `billing-app`     | StatefulSet            | 8080 | Billing consumer/API  |
| `api-gateway-app` | Deployment             | 3000 | External API gateway  |

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

The gateway is available at `http://192.168.60.10:3000` while the cluster is
running. Example requests:

```sh
curl -X POST http://192.168.60.10:3000/api/movies/ \
  -H 'Content-Type: application/json' \
  -d '{"title":"A new movie","description":"Very short description"}'

curl http://192.168.60.10:3000/api/movies/

curl -X POST http://192.168.60.10:3000/api/billing/ \
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

## AWS EKS Deployment

`terraform/` provisions an EKS control plane, a minimal managed node group in
public subnets, EBS CSI storage support, and ECR repositories. Terraform does
not deploy application resources. The application continues to use its
Kubernetes manifests and self-hosted PostgreSQL and RabbitMQ workloads.

Provision the cluster and configure `kubectl`:

```sh
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
terraform -chdir=terraform init
terraform -chdir=terraform apply
aws eks update-kubeconfig --region eu-west-3 --name cloud-design
```

Build and push all application images with an immutable release tag. AWS CLI
credentials and a default region must already be configured:

```sh
./Scripts/push-ecr-images.sh v1
```

The script logs Docker into ECR and prints the six ECR image references. Update
the `image:` values in `Manifests/` with those references, then create the
credentials Secret and deploy:

```sh
KUBECONFIG="$HOME/.kube/config" ./Scripts/create-local-secret.sh
kubectl apply -f Manifests
kubectl get service api-gateway-app --watch
```

The EKS gateway uses a `LoadBalancer` Service, so AWS publishes its hostname in
the service's `EXTERNAL-IP` column. The public-node design avoids NAT gateway
costs and is suitable only for a minimal development environment.

Terraform installs EBS storage, Metrics Server, and Cluster Autoscaler. Metrics
Server enables the existing CPU-based HPAs. Cluster Autoscaler detects
unschedulable pods created by those HPAs and adjusts the managed node group
between one and three nodes. Terraform needs AWS CLI access because its Helm
and Kubernetes providers authenticate with `aws eks get-token`.

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
- K3s exposes the LoadBalancer Service on the gateway's service port for local
  development; EKS creates an AWS load balancer for the same Service.
- The EKS setup is intentionally minimal. It does not include private worker
  subnets, NAT gateways, managed databases, managed RabbitMQ, HTTPS,
  authentication, or centralized AWS observability.
