output "user_name" {
  value       = aws_iam_user.user.name
  description = "User name"
}

output "unique_id" {
  value       = aws_iam_user.user.unique_id
  description = "User uniq_id"
}

output "access_key_id" {
  value = aws_iam_access_key.user_access_key.id
}

output "secret_access_key" {
  value = aws_iam_access_key.user_access_key.secret
}
