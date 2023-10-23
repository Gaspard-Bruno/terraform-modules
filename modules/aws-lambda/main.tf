data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = var.source_file
  output_path = var.output_path
  # source_file = "../lambdas/create_federated_user/index.js"
  # output_path = "create_federated_user_payload.zip"
}

data "hcp_vault_secrets_app" "example" {
  app_name = "gbaccesscontrol-production"
}

resource "aws_lambda_function" "lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "create_federated_user_payload.zip"
  function_name = var.lambda_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "nodejs18.x"

  environment {
    variables = {
      API_URL = data.hcp_vault_secrets_app.example.secrets.API_URL
    }
  }
}
