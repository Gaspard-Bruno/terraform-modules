output "lambda_arn" {
  value       = aws_lambda_function.lambda.arn
  description = "Ecr Repo Arn"
}
