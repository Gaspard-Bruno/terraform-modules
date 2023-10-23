data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["cognito-idp.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ses_role" {
  name               = "${var.project_name}-${terraform.workspace}-cognito-ses-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "role_policy" {
  statement {
    sid     = "AllowSNSPublish"
    effect  = "Allow"
    actions = ["sns:publish"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "managed_policy" {
  name = "${var.project_name}-${terraform.workspace}-cognito-ses-policy"
  policy = data.aws_iam_policy_document.role_policy.json
}

resource "aws_iam_role_policy_attachment" "managed_policy_attach" {
  role = aws_iam_role.ses_role.name
  policy_arn = aws_iam_policy.managed_policy.arn
}

data "aws_ses_email_identity" "ses_identity" {
  email = "ops@gaspardbruno.com"
}

module "aws_sign_up_lambda" {
  source = "../aws-lambda"

  lambda_name = "${var.project_name}-${terraform.workspace}-federated-login"
  source_file = "../lambdas/create_federated_user/index.js"
  output_path = "create_federated_user_payload.zip"
}

resource "aws_cognito_user_pool" "pool" {
  name = "${var.cognito_pool_name}"

  username_attributes = ["email", "phone_number"]
  mfa_configuration = "ON"
  auto_verified_attributes = ["phone_number"]

  lambda_config {
    pre_sign_up = module.aws_sign_up_lambda.lambda_arn
  }
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_phone_number"
      priority = 1
    }
    recovery_mechanism {
      name     = "verified_email"
      priority = 2
    }
  }
  email_configuration {
    source_arn = data.aws_ses_email_identity.ses_identity.arn
    email_sending_account = "DEVELOPER"
    from_email_address = "GB Access <ops@gaspardbruno.com>"
  }
  sms_configuration {
    external_id    = "example"
    sns_caller_arn = aws_iam_role.ses_role.arn
    sns_region     = "eu-west-1"
  }

  user_attribute_update_settings {
    attributes_require_verification_before_update = ["phone_number"]
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true
    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }

  schema {
    name                = "phone_number"
    attribute_data_type = "String"
    mutable             = true
    # required            = true
    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }

  software_token_mfa_configuration {
    enabled = true
  }
}

resource "aws_lambda_permission" "allow_execution_from_user_pool" {
  statement_id = "AllowExecutionFromUserPool"
  action = "lambda:InvokeFunction"
  function_name = module.aws_sign_up_lambda.lambda_arn
  principal = "cognito-idp.amazonaws.com"
  source_arn = aws_cognito_user_pool.pool.arn
}

data "hcp_vault_secrets_app" "example" {
  app_name = "gbaccesscontrol-production"
}

resource "aws_cognito_user_pool_domain" "user" {
  domain       = "${var.project_name}-${terraform.workspace}-user"
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_identity_provider" "google" {
  user_pool_id  = aws_cognito_user_pool.pool.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    authorize_scopes = "email openid profile"
    client_id        = data.hcp_vault_secrets_app.example.secrets.GOOGLE_OAUTH_CLIENT_ID
    client_secret    = data.hcp_vault_secrets_app.example.secrets.GOOGLE_OAUTH_CLIENT_SECRET
  }

  attribute_mapping = {
    email          = "email"
    username       = "sub"
    email_verified = "email_verified"
    family_name    = "family_name"
    given_name     = "given_name"
    phone_number   = "phoneNumbers"
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name = "api"

  user_pool_id = aws_cognito_user_pool.pool.id

  generate_secret     = true
  explicit_auth_flows = [
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
  auth_session_validity  = 3
  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 31

  token_validity_units {
    access_token = "days"
    id_token = "days"
    refresh_token = "days"
  }

  supported_identity_providers  = [
    aws_cognito_identity_provider.google.provider_name
  ]

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = [
    "email",
    "openid",
    "profile",
  ]
  callback_urls = [
    "${data.hcp_vault_secrets_app.example.secrets.API_URL}/v1/webhooks/aws/federated_lambda_callback"
  ]
}
