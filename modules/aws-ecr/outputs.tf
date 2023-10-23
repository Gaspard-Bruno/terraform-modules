output "ecr_repo_arn" {
  value       = aws_ecr_repository.ecr_repo.arn
  description = "Ecr Repo Arn"
}
