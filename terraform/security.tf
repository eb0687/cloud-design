resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb"
  description = "Public ingress boundary for the application load balancer."
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.allowed_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP is accepted only to redirect clients to HTTPS."
  cidr_ipv4         = each.value
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = toset(var.allowed_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "Public HTTPS access to the API."
  cidr_ipv4         = each.value
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_security_group" "eks_nodes" {
  name        = "${local.name_prefix}-eks-nodes"
  description = "Network boundary for EKS worker nodes and application workloads."
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.name_prefix}-eks-nodes"
  }
}

resource "aws_vpc_security_group_egress_rule" "alb_to_api_gateway" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward API traffic and health checks to the gateway workload."
  referenced_security_group_id = aws_security_group.eks_nodes.id
  from_port                    = var.api_gateway_port
  ip_protocol                  = "tcp"
  to_port                      = var.api_gateway_port
}

resource "aws_vpc_security_group_ingress_rule" "eks_nodes_from_alb" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Accept API traffic and health checks only from the load balancer."
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.api_gateway_port
  ip_protocol                  = "tcp"
  to_port                      = var.api_gateway_port
}

resource "aws_vpc_security_group_ingress_rule" "eks_nodes_internal" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Allow Kubernetes nodes and pods to communicate within the cluster."
  referenced_security_group_id = aws_security_group.eks_nodes.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "eks_nodes_all" {
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow image pulls, AWS API calls, and outbound application dependencies."
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
