# Local Baseline Evidence

This evidence records the local Vagrant/K3s verification performed after the
storage-class correction.

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
