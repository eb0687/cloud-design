resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    encrypted = "true"
    type      = "gp3"
  }

  depends_on = [aws_eks_addon.ebs_csi, aws_eks_node_group.main]
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.13.0"
  namespace  = "kube-system"

  atomic  = true
  timeout = 300
  wait    = true

  values = [yamlencode({
    args = [
      "--kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP",
      "--kubelet-use-node-status-port",
    ]
  })]

  depends_on = [aws_eks_node_group.main]
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.53.0"
  namespace  = "kube-system"

  atomic  = true
  timeout = 300
  wait    = true

  values = [yamlencode({
    autoDiscovery = {
      clusterName = aws_eks_cluster.main.name
    }
    awsRegion = var.aws_region
    extraArgs = {
      "balance-similar-node-groups" = "true"
      "skip-nodes-with-system-pods" = "false"
    }
    rbac = {
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler.arn
        }
        create = true
        name   = "cluster-autoscaler"
      }
    }
  })]

  depends_on = [aws_iam_role_policy.cluster_autoscaler, aws_eks_node_group.main]
}
