resource "kubernetes_secret_v1" "orchestrator" {
  metadata {
    name      = "orchestrator-secrets"
    namespace = var.kubernetes_namespace
  }

  data = var.orchestrator_secret_values

  depends_on = [aws_eks_node_group.default]
}
