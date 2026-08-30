# Local Monitoring Evidence

This evidence records the monitoring implementation verified in the local K3s
cluster.

The first monitoring image used a third-party middleware that caused HTTP 500
responses for gateway routes backed by included FastAPI routers. It was replaced
with the project-owned middleware in `Dockerfiles/packages/metrics`, and the
`monitoring-5` images were rebuilt and deployed. Inventory and billing POST
requests returned successfully after that rollout.

## Deployment

The pinned `kube-prometheus-stack` Helm release was installed in the
`monitoring` namespace using:

```sh
./Monitoring/install.sh
```

The following monitoring workloads were Running:

- Prometheus
- Grafana
- Alertmanager
- Prometheus Operator
- kube-state-metrics
- Two node-exporter pods

Prometheus, Grafana, and Alertmanager PVCs were `Bound` using the K3s
`local-path` StorageClass.

## Targets

The following ServiceMonitor targets returned `up = 1` from Prometheus:

- `api-gateway-app`
- `inventory-app`
- `billing-app`
- `rabbitmq`

The three FastAPI targets exposed `http_requests_total`. RabbitMQ exposed
`rabbitmq_queue_messages_ready` and
`rabbitmq_queue_consumers`.

The application metrics middleware excludes Kubernetes requests whose
`User-Agent` begins with `kube-probe/`, so request-rate and 5xx panels represent
application traffic rather than readiness and liveness probes.

## Dashboard and Rules

- The Grafana health endpoint returned `database: ok`.
- The dashboard sidecar loaded `cloud-design-overview.json` and reloaded it
  successfully.
- Prometheus registered six Cloud-Design rules:
  `CloudDesignServiceDown`, `CloudDesignHigh5xxRate`,
  `CloudDesignContainerRestarts`, `CloudDesignHPAAtMaximum`,
  `CloudDesignRabbitMQQueueGrowing`, and
  `CloudDesignRabbitMQNoConsumers`.

The Service Availability panel uses Kubernetes ready-replica metrics rather
than scrape history. Deployments use
`kube_deployment_status_replicas_ready`; billing uses
`kube_statefulset_status_replicas_ready`. A workload scaled to zero therefore
displays `DOWN` instead of retaining its last successful scrape value.

The inventory failure test scaled `inventory-app` to zero and sent a request
through the gateway. It returned HTTP `503`, and the dashboard showed inventory
as `DOWN`. After restoring one replica, the request returned HTTP `200` and the
gauge returned to `UP`. The local high-5xx alert uses a one-minute pending
period.

Access Grafana locally with:

```sh
KUBECONFIG=.kube/config kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
```
