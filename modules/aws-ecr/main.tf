resource "aws_ecr_repository" "ecr_repo" {
  name                 = "${var.repo_name}"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository" "ecr_repo_stages" {
  name                 = "${var.repo_name}-stages"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "clean_policy" {
  repository = aws_ecr_repository.ecr_repo.name

  policy = <<EOF
    {
      "rules": [
        {
          "rulePriority": 1,
          "description": "Keep last 3 untagged images",
          "selection": {
            "tagStatus": "untagged",
            "countType": "imageCountMoreThan",
            "countNumber": 3
          },
          "action": {
            "type": "expire"
          }
        },
        {
          "rulePriority": 2,
          "description": "Keep last 3 ${terraform.workspace} images",
          "selection": {
            "tagStatus": "tagged",
            "tagPrefixList": ["${terraform.workspace}"],
            "countType": "imageCountMoreThan",
            "countNumber": 3
          },
          "action": {
            "type": "expire"
          }
        }
      ]
    }
  EOF
}

resource "aws_ecr_lifecycle_policy" "clean_policy_stages" {
  repository = aws_ecr_repository.ecr_repo_stages.name

  policy = <<EOF
    {
      "rules": [
        {
          "rulePriority": 1,
          "description": "Keep last 3 untagged images",
          "selection": {
            "tagStatus": "untagged",
            "countType": "imageCountMoreThan",
            "countNumber": 3
          },
          "action": {
            "type": "expire"
          }
        },
        {
          "rulePriority": 2,
          "description": "Keep last 3 ${terraform.workspace} images",
          "selection": {
            "tagStatus": "tagged",
            "tagPrefixList": ["${terraform.workspace}"],
            "countType": "imageCountMoreThan",
            "countNumber": 3
          },
          "action": {
            "type": "expire"
          }
        }
      ]
    }
  EOF
}
