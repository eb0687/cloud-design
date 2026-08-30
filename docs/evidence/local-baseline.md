# Local Baseline Evidence

This evidence records the local Vagrant/K3s verification performed after the
storage-class correction.

The cluster was later recreated with `./orchestrator.sh destroy` followed by
`./orchestrator.sh create`. The current verification below reflects the fresh
local deployment and the monitoring configuration documented in
`docs/evidence/monitoring.md`.

## Storage

Command:

```sh
KUBECONFIG=.kube/config kubectl get storageclass
KUBECONFIG=.kube/config kubectl get pvc
```

Result:

- K3s `local-path` is the default StorageClass.
- `billing-db-data-billing-db-0` is `Bound`.
- `inventory-db-data-inventory-db-0` is `Bound`.
- `rabbitmq-data` is `Bound`.

## Service Health

`./orchestrator.sh verify` completed successfully. Both nodes were Ready, all
six application pods were Running, all service endpoints were populated, and
the gateway and inventory HPAs reported CPU metrics with a 60% target.

## Inventory API

```sh
curl --fail http://192.168.60.10:30000/api/movies/
```

The gateway returned HTTP 200 with an empty list before the test movie was
created. A subsequent POST created movie `Cloud Design test`, and a GET
returned that movie through the gateway.

## Billing Queue Recovery

The billing consumer was scaled to zero, then this request was submitted:

```sh
curl -X POST http://192.168.60.10:30000/api/billing/ \
  -H 'Content-Type: application/json' \
  -d '{"user_id":21,"number_of_items":3,"total_amount":40}'
```

The gateway returned `{"status":"queued"}`. After scaling `billing-app` back
to one replica, rollout completed and the billing logs reported:

```text
Listening on RabbitMQ queue billing_queue
Saved billing order 2
```

This demonstrates queued-message recovery for the local deployment.

## Inventory Failure and Recovery

The inventory Deployment was scaled to zero:

```sh
KUBECONFIG=.kube/config kubectl scale deployment/inventory-app --replicas=0
curl -i http://192.168.60.10:30000/api/movies/
```

The gateway returned HTTP `503 Service Unavailable`. The inventory workload
was then restored with one replica and the same request returned HTTP `200 OK`.

The Service Availability gauge changed to `DOWN` at zero ready replicas and
returned to `UP` after recovery. The HTTP 5xx alert uses a one-minute pending
period for local demonstration.

## Current Verification Limits

- Database-unavailability and broker-unavailability failure tests have not
  been run in the current fresh cluster.
- AWS deployment, AWS autoscaling, AWS monitoring, and AWS billing evidence
  remain unverified because no AWS account is available.

## Container and Terraform Checks

The monitoring application images were built and pushed with the commands in
`Monitoring/README.md`. The resulting local image sizes were:

```text
eb0687/api-gateway-app:monitoring-5 264MB
eb0687/billing-app:monitoring-5     264MB
eb0687/inventory-app:monitoring-5   264MB
eb0687/rabbitmq:monitoring-1        102MB
```

Terraform formatting and validation completed successfully:

```sh
terraform -chdir=terraform fmt -check
terraform -chdir=terraform init -backend=false -input=false
terraform -chdir=terraform validate
```
