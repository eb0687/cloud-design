locals {
  api_load_balancer_name = trim(substr("${local.name_prefix}-api", 0, 32), "-")
}

resource "kubernetes_ingress_v1" "api" {
  metadata {
    name = "api-gateway"

    annotations = {
      "alb.ingress.kubernetes.io/auth-idp"                        = jsonencode({ type = "cognito", userPoolARN = aws_cognito_user_pool.api.arn, userPoolClientID = aws_cognito_user_pool_client.api_alb.id, userPoolDomain = aws_cognito_user_pool_domain.api.domain })
      "alb.ingress.kubernetes.io/auth-on-unauthenticated-request" = "authenticate"
      "alb.ingress.kubernetes.io/auth-scope"                      = "openid"
      "alb.ingress.kubernetes.io/auth-session-timeout"            = "3600"
      "alb.ingress.kubernetes.io/auth-type"                       = "cognito"
      "alb.ingress.kubernetes.io/certificate-arn"                 = aws_acm_certificate_validation.api.certificate_arn
      "alb.ingress.kubernetes.io/listen-ports"                    = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/load-balancer-name"              = local.api_load_balancer_name
      "alb.ingress.kubernetes.io/scheme"                          = "internet-facing"
      "alb.ingress.kubernetes.io/security-groups"                 = aws_security_group.alb.id
      "alb.ingress.kubernetes.io/ssl-redirect"                    = "443"
      "alb.ingress.kubernetes.io/target-type"                     = "ip"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = local.api_domain_name

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "api-gateway-app"

              port {
                number = var.api_gateway_port
              }
            }
          }
        }
      }
    }
  }

  wait_for_load_balancer = true

  depends_on = [
    helm_release.aws_load_balancer_controller,
    aws_acm_certificate_validation.api,
    aws_cognito_user_pool_domain.api,
  ]
}

data "aws_lb" "api" {
  name = local.api_load_balancer_name

  depends_on = [kubernetes_ingress_v1.api]
}

resource "aws_route53_record" "api" {
  name    = local.api_domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.public.zone_id

  alias {
    evaluate_target_health = true
    name                   = data.aws_lb.api.dns_name
    zone_id                = data.aws_lb.api.zone_id
  }
}
