output "cognito_pool_arn" {
  value = aws_cognito_user_pool.pool.arn
}

output "cognito_pool_id" {
  value = aws_cognito_user_pool.pool.id
}

output "cognito_pool_client_id" {
  value = aws_cognito_user_pool_client.client.id
}

output "cognito_pool_client_secret" {
  value = aws_cognito_user_pool_client.client.client_secret
}
