# Local Observability

The Cloud-Design observability target is local-first because no AWS account is
available. Kubernetes should expose application logs through stdout/stderr and
metrics through a Prometheus-compatible endpoint. Prometheus and Grafana can be
installed in the K3s cluster using the `kube-prometheus-stack` chart or an
equivalent reviewed deployment.

## Minimum Evidence

- Capture application pod logs with `kubectl logs`.
- Record request success/error rates for the gateway and both apps.
- Record CPU and memory usage for HPA-managed workloads.
- Record RabbitMQ queue depth and consumer availability.
- Create dashboards for service health, resources, HTTP traffic, and queue
  processing.
- Create alerts for unavailable replicas, failed probes, elevated 5xx responses,
  queue growth, and resource exhaustion.

## Monitoring Images

The application and RabbitMQ metrics require new public images. After starting
the Docker daemon and authenticating to Docker Hub, build and push the images:

```sh
docker login
cd Dockerfiles
docker build -f apps/inventory/Dockerfile -t eb0687/inventory-app:monitoring-5 .
docker build -f apps/billing/Dockerfile -t eb0687/billing-app:monitoring-5 .
docker build -f apps/gateway/Dockerfile -t eb0687/api-gateway-app:monitoring-5 .
docker build -f docker/rabbit-queue/Dockerfile -t eb0687/rabbitmq:monitoring-1 .
docker push eb0687/inventory-app:monitoring-5
docker push eb0687/billing-app:monitoring-5
docker push eb0687/api-gateway-app:monitoring-5
docker push eb0687/rabbitmq:monitoring-1
cd ..
```

The application manifests use the `monitoring-5` tags and RabbitMQ uses
`monitoring-1`. Reconcile the workloads before checking Prometheus targets.
The existing `latest` images remain available as the previous baseline.

## AWS Mapping

| Local signal | Proposed AWS equivalent |
| --- | --- |
| `kubectl logs` | CloudWatch Container Insights and log groups |
| Prometheus metrics | Amazon Managed Service for Prometheus or Prometheus on EKS |
| Grafana dashboards | Amazon Managed Grafana or Grafana on EKS |
| Kubernetes alerts | Amazon Managed Service for Prometheus alerting/Alertmanager |

These AWS services are design targets only. They have not been provisioned or
verified.

The verified local results are recorded in `docs/evidence/monitoring.md`.

## Install Locally

The install script adds the Prometheus Community chart repository, installs a
pinned `kube-prometheus-stack` release, and applies the application scrape
targets, alert rules, and dashboard:

```sh
chmod +x Monitoring/install.sh
./Monitoring/install.sh
```

The script uses K3s's `local-path` StorageClass and does not create an ingress.
Access the UI only through local port forwarding:

```sh
KUBECONFIG=.kube/config kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
```

Retrieve the generated Grafana admin password from the Kubernetes Secret:

```sh
KUBECONFIG=.kube/config kubectl -n monitoring get secret monitoring-grafana \
  -o jsonpath='{.data.admin-password}' | base64 -d; printf '\n'
```
