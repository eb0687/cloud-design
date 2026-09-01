resource "aws_cognito_user_pool" "api" {
  name                     = "${local.name_prefix}-api"
  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  tags = {
    Name = "${local.name_prefix}-api"
  }
}

resource "aws_cognito_user_pool_client" "api_alb" {
  name                                 = "${local.name_prefix}-alb"
  user_pool_id                         = aws_cognito_user_pool.api.id
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = ["https://${local.api_domain_name}/oauth2/idpresponse"]
  generate_secret                      = true
  logout_urls                          = ["https://${local.api_domain_name}/"]
  prevent_user_existence_errors        = "ENABLED"
  supported_identity_providers         = ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "api" {
  domain       = var.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.api.id
}
