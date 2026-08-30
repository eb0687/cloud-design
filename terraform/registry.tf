resource "aws_ecr_repository" "service" {
  for_each = toset([
    "api-gateway-app",
    "inventory-app",
    "billing-app",
  ])

  name                 = "${local.name}/${each.key}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
