resource "aws_cloudwatch_log_group" "eks_control_plane" {
  name              = "/aws/eks/${local.name_prefix}/cluster"
  retention_in_days = var.cloudwatch_log_retention_days
}

resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/eks/${local.name_prefix}/application"
  retention_in_days = var.cloudwatch_log_retention_days
}

data "aws_iam_policy_document" "fluent_bit_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:amazon-cloudwatch:aws-for-fluent-bit"]
    }
  }
}

resource "aws_iam_role" "fluent_bit" {
  name               = "${local.name_prefix}-fluent-bit"
  assume_role_policy = data.aws_iam_policy_document.fluent_bit_assume_role.json
}

resource "aws_iam_role_policy_attachment" "fluent_bit" {
  role       = aws_iam_role.fluent_bit.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "helm_release" "aws_for_fluent_bit" {
  name             = "aws-for-fluent-bit"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-for-fluent-bit"
  version          = var.aws_for_fluent_bit_chart_version
  namespace        = "amazon-cloudwatch"
  create_namespace = true

  set {
    name  = "cloudWatch.enabled"
    value = "true"
  }

  set {
    name  = "cloudWatch.logGroupName"
    value = aws_cloudwatch_log_group.application.name
  }

  set {
    name  = "cloudWatch.region"
    value = var.aws_region
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-for-fluent-bit"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.fluent_bit.arn
  }

  depends_on = [
    aws_eks_node_group.default,
    aws_iam_role_policy_attachment.fluent_bit,
  ]
}
