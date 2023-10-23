output "db_username" {
  value       = aws_db_instance.db_instance.username
  description = "The username for logging in to the database."
}

output "db_endpoint" {
  value       = aws_db_instance.db_instance.endpoint
  description = "The endpoint for logging in to the database."
}
