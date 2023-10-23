output "rds_username" {
  value = module.rds_database.db_username
  description = "The password for logging in to the database."
}

output "rds_endpoint" {
  value = module.rds_database.db_endpoint
  description = "The password for logging in to the database."
}

output "redis_endpoint" {
  value = module.redis_database.redis_endpoint
  description = "The password for logging in to the database."
}

output "user_github_name" {
  value = module.iam_user_github.user_name
  description = "The password for logging in to the database."
}

output "user_github_access_key_id" {
  value = module.iam_user_github.access_key_id
  description = "The password for logging in to the database."
}

output "user_github_secret_access_key" {
  value = nonsensitive(module.iam_user_github.secret_access_key)
  description = "The password for logging in to the database."
}

output "user_api_name" {
  value = module.iam_user_api.user_name
  description = "The password for logging in to the database."
}

output "user_api_access_key_id" {
  value = module.iam_user_api.access_key_id
  description = "The password for logging in to the database."
}

output "user_api_secret_access_key" {
  value = nonsensitive(module.iam_user_api.secret_access_key)
  description = "The password for logging in to the database."
}

output "cognito_pool_arn" {
  value = module.cognito.cognito_pool_arn
  description = "The password for logging in to the database."
}

output "cognito_pool_id" {
  value = module.cognito.cognito_pool_id
  description = "The password for logging in to the database."
}

output "cognito_pool_client_id" {
  value = module.cognito.cognito_pool_client_id
  description = "The password for logging in to the database."
}

output "cognito_pool_client_secret" {
  value = nonsensitive(module.cognito.cognito_pool_client_secret)
  description = "The password for logging in to the database."
}

output "ecr_repo_arn" {
  value = module.ecr.ecr_repo_arn
  description = "Ecr Repo Arn"
}
