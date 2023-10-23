locals {
  tfsettingsfile        = "secret.${terraform.workspace}.yaml"
  tfsettingsfilecontent = fileexists(local.tfsettingsfile) ? file(local.tfsettingsfile) : "NoTFSettingsFileFound: true"
  tfworkspacesettings   = yamldecode(local.tfsettingsfilecontent)
  tfsettings            = local.tfworkspacesettings
}

terraform {
  backend "s3" {
    bucket = "xxxxxxxxxxxxxxxxxxx" // <--- add bucket name 
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.5.0"
    }

    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.68.0"
    }
  }
}

provider "hcp" {
  client_id     = ""
  client_secret = ""
  project_id    = ""
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "example" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "cognito" {
  source = "./modules/aws-cognito"

  project_name      = var.project_name
  cognito_pool_name = "${var.project_name}-${terraform.workspace}-user"
}

module "iam_user_github" {
  source = "./modules/aws-user"

  user_name = "${var.project_name}-${terraform.workspace}-github"
  custom_policies = toset([
    {
      name = "${var.project_name}-${terraform.workspace}-ecr-policy"
      statements = [{
        actions = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:UploadLayerPart",
          "ecr:ListImages",
          "ecr:InitiateLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetRepositoryPolicy",
          "ecr:PutImage"
        ],
        effect    = "Allow",
        resources = ["*"]
        },
        {
          actions   = ["ecr:ListImages"],
          effect    = "Allow",
          resources = ["*"]
      }]
    }
  ])
}

module "iam_user_api" {
  source = "./modules/aws-user"

  user_name = "${var.project_name}-${terraform.workspace}-api"
  policy_arns = toset([
    "AmazonCognitoPowerUser",
    "AmazonSESFullAccess"
  ])
}

module "rds_database" {
  source = "./modules/aws-rds"

  rds_name        = "${var.project_name}-${terraform.workspace}"
  initial_db_name = terraform.workspace
  vpc_id          = data.aws_vpc.default.id
  office_ip       = var.office_ip
}

module "redis_database" {
  source = "./modules/aws-redis"

  redis_name     = "${var.project_name}-${terraform.workspace}"
  vpc_id         = data.aws_vpc.default.id
  vpc_subnet_ids = toset(data.aws_subnets.example.ids)
}

module "ecr" {
  source = "./modules/aws-ecr"

  repo_name = "${var.project_name}-${terraform.workspace}"
}

module "ecs" {
  source = "./modules/aws-ecs"

  vpc_id         = data.aws_vpc.default.id
  vpc_subnet_ids = toset(data.aws_subnets.example.ids)

  image_name   = "${var.project_name}-${terraform.workspace}"
  cluster_name = "${var.project_name}-${terraform.workspace}"
  task_name    = "${var.project_name}-${terraform.workspace}-api"
  task_cpu     = 256
  task_memory  = 512
  # container_name = "api"
  # container_image = "ankane/pghero:latest"
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_region            = var.aws_region
  aws_account_id        = var.aws_account_id
}


