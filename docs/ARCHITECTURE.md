# Architecture

## Demonstrated Local Architecture

```mermaid
flowchart LR
    Client --> Gateway[API gateway :3000]
    Gateway --> Inventory[inventory-app :8080]
    Gateway --> Billing[billing-app :8080]
    Inventory --> InventoryDB[(inventory-db PostgreSQL :5432)]
    Billing --> BillingDB[(billing-db PostgreSQL :5432)]
    Gateway --> Rabbit[(RabbitMQ :5672)]
    Billing --> Rabbit
```

The gateway is exposed through the local K3s LoadBalancer Service. Application services,
databases, and RabbitMQ use Kubernetes Services and are not directly exposed
to the host. The database workloads use StatefulSets and persistent volume
claims. The gateway and inventory app use HPAs with one to three replicas and a
60% CPU target.

## Minimal AWS EKS Architecture

```mermaid
flowchart TB
    User --> LB[Public Kubernetes load balancer]
    LB --> Gateway[EKS API gateway]
    Gateway --> Inventory[inventory-app]
    Gateway --> Rabbit[(RabbitMQ)]
    Inventory --> InventoryDB[(PostgreSQL)]
    Billing[billing-app] --> Rabbit
    Billing --> BillingDB[(PostgreSQL)]
    Public[Public subnets] --- EKS[EKS control plane and managed nodes]
    EKS --- Gateway
    EKS --- Inventory
    EKS --- Billing
```

Terraform provisions the EKS cluster, networking, EBS CSI add-on, ECR
repositories, `gp3` StorageClass, Metrics Server, and Cluster Autoscaler. The
application resources remain outside Terraform and are deployed with
`kubectl apply -f Manifests`.

## Boundaries

- Public traffic reaches only the gateway through its Kubernetes LoadBalancer
  Service.
- Databases and RabbitMQ remain internal Kubernetes Services.
- EBS CSI dynamically provisions encrypted `gp3` volumes for persistent data.
- Credentials come from an ignored local file and are created as a Kubernetes
  Secret before applying the application manifests.
- This cost-minimized EKS setup has public worker nodes and no HTTPS,
  authentication, managed data services, or centralized AWS observability.
- Metrics Server supplies CPU metrics to the existing HPAs. Cluster Autoscaler
  increases or decreases the managed node group between one and three nodes.
