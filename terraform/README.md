# Minimal EKS Terraform

This directory provisions the smallest AWS foundation needed to run the
existing Kubernetes application: an EKS control plane, a managed public-node
group, EBS CSI storage support, platform add-ons, and ECR repositories.
Terraform manages the `gp3` StorageClass, Metrics Server, and Cluster
Autoscaler. Deploy the application resources separately with `kubectl`.

The worker nodes are in public subnets to avoid a NAT gateway. This is a
cost-minimized environment, not a production network design. The current
configuration requires an AWS account and credentials with permission to
create the listed resources.

The cluster has one node by default and can scale to three nodes. Metrics Server
feeds the existing HPAs; Cluster Autoscaler adds nodes when the resulting pods
cannot be scheduled.

## Provisioning

Copy the example values and adjust them if needed:

```sh
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
terraform -chdir=terraform init
terraform -chdir=terraform apply
```

Configure `kubectl` after Terraform completes:

```sh
aws eks update-kubeconfig --region eu-west-3 --name cloud-design
kubectl get nodes
```

Build and push all six images with an immutable release tag. The AWS CLI must
already be authenticated and have a default region configured. The script logs
Docker into ECR, builds every image, pushes it, and prints the resulting image
references:

```sh
./Scripts/push-ecr-images.sh v1
```

Set `PROJECT_NAME` when it differs from Terraform's default `cloud-design`:

```sh
PROJECT_NAME=my-project ./Scripts/push-ecr-images.sh v1
```

Update the six `image:` values in `Manifests/` with the printed ECR references.
Then create the application credentials and deploy the manifests:

```sh
KUBECONFIG="$HOME/.kube/config" ./Scripts/create-local-secret.sh
kubectl apply -f Manifests
kubectl get service api-gateway-app --watch
```

The gateway service creates a public AWS load balancer. Its hostname is shown
in the `EXTERNAL-IP` column once provisioning completes.

Terraform requires AWS CLI access because its Kubernetes and Helm providers
use `aws eks get-token` to access the EKS API. It installs Metrics Server and
Cluster Autoscaler in `kube-system`. Cluster Autoscaler discovers only the
managed node group tagged by Terraform and adjusts it between one and three
nodes. Confirm their status with:

```sh
kubectl -n kube-system get deployment metrics-server cluster-autoscaler
kubectl get hpa
kubectl get nodes
```

## Static Checks

```sh
terraform -chdir=terraform fmt -check
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
```

Delete the kubectl-managed application resources before destroying the cluster.
This removes the gateway load balancer before Terraform deletes its VPC:

```sh
kubectl delete -f Manifests
```

Then destroy all Terraform-managed cloud and platform resources:

```sh
terraform -chdir=terraform destroy
```
