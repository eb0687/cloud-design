# Local Observability

The Cloud-Design observability target is local-first because no AWS account is
available. Kubernetes should expose application logs through stdout/stderr and
metrics through a Prometheus-compatible endpoint. Prometheus and Grafana can be
installed in the K3s cluster using the `kube-prometheus-stack` chart or an
equivalent reviewed deployment.

## Minimum Evidence

- Capture application pod logs with `kubectl logs`.
- Record request success/error rates and latency for the gateway and both apps.
- Record CPU and memory usage for HPA-managed workloads.
- Record RabbitMQ queue depth and consumer availability.
- Create dashboards for service health, resources, HTTP traffic, and queue
  processing.
- Create alerts for unavailable replicas, failed probes, elevated 5xx responses,
  high latency, queue growth, and resource exhaustion.

## AWS Mapping

| Local signal | Proposed AWS equivalent |
| --- | --- |
| `kubectl logs` | CloudWatch Container Insights and log groups |
| Prometheus metrics | Amazon Managed Service for Prometheus or Prometheus on EKS |
| Grafana dashboards | Amazon Managed Grafana or Grafana on EKS |
| Kubernetes alerts | Amazon Managed Service for Prometheus alerting/Alertmanager |

These AWS services are design targets only. They have not been provisioned or
verified.
