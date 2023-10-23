resource "aws_ecs_cluster" "foo" {
  name = "${var.cluster_name}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

resource "null_resource" "docker_packaging" {
  provisioner "local-exec" {
    command = <<EOF
      export AWS_ACCESS_KEY_ID=${var.aws_access_key_id}
      export AWS_SECRET_ACCESS_KEY=${var.aws_secret_access_key}
      export AWS_DEFAULT_REGION=${var.aws_region}
      aws ecr get-login-password --region ${var.aws_region} | \
        docker login \
        --username AWS \
        --password-stdin ${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
      docker build \
        -t "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.image_name}" \
        -f ../backend/backend.dockerfile \
        ../backend
      docker push "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.image_name}"
    EOF
  }

  triggers = {
    "run_at" = timestamp()
  }
}

data "hcp_vault_secrets_app" "example" {
  app_name = "gbaccesscontrol-production"
}

resource "aws_cloudwatch_log_group" "api" {
  name = "${var.task_name}-api"
}

resource "aws_ecs_task_definition" "github_backup" {
  skip_destroy             = true
  family                   = "${var.task_name}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "${var.task_cpu}"
  memory                   = "${var.task_memory}"
  # task_role_arn            = "${aws_iam_role.github-role.arn}"
  task_role_arn            = "${data.aws_iam_role.ecs_task_execution_role.arn}"
  execution_role_arn       = "${data.aws_iam_role.ecs_task_execution_role.arn}"

  container_definitions = <<DEFINITION
  [
    {
      "cpu": ${var.task_cpu},
      "image": "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.image_name}:latest",
      "memory": ${var.task_memory},
      "name": "api",
      "networkMode": "awsvpc",
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "environment": [
        {"name": "ENV", "value": "${terraform.workspace}"},
        {"name": "PORT", "value": "80"},
        {"name": "API_URL", "value": "${data.hcp_vault_secrets_app.example.secrets.API_URL}"},
        {"name": "AWS_ACCESS_KEY_ID", "value": "${data.hcp_vault_secrets_app.example.secrets.AWS_ACCESS_KEY_ID}"},
        {"name": "AWS_REGION", "value": "${data.hcp_vault_secrets_app.example.secrets.AWS_REGION}"},
        {"name": "AWS_SECRET_ACCESS_KEY", "value": "${data.hcp_vault_secrets_app.example.secrets.AWS_SECRET_ACCESS_KEY}"},
        {"name": "COGNITO_REGION", "value": "${data.hcp_vault_secrets_app.example.secrets.COGNITO_REGION}"},
        {"name": "POSTGRES_PASSWORD", "value": "${data.hcp_vault_secrets_app.example.secrets.POSTGRES_PASSWORD}"},
        {"name": "POSTGRES_SERVER", "value": "${data.hcp_vault_secrets_app.example.secrets.POSTGRES_SERVER}"},
        {"name": "POSTGRES_USER", "value": "${data.hcp_vault_secrets_app.example.secrets.POSTGRES_USER}"},
        {"name": "POSTGRES_DB", "value": "${data.hcp_vault_secrets_app.example.secrets.POSTGRES_DB}"},
        {"name": "PROJECT_NAME", "value": "${data.hcp_vault_secrets_app.example.secrets.PROJECT_NAME}"},
        {"name": "USER_COGNITO_API_SECRET", "value": "${data.hcp_vault_secrets_app.example.secrets.USER_COGNITO_API_SECRET}"},
        {"name": "USER_COGNITO_APP_CLIENT_ID", "value": "${data.hcp_vault_secrets_app.example.secrets.USER_COGNITO_APP_CLIENT_ID}"},
        {"name": "USER_COGNITO_POOL_ID", "value": "${data.hcp_vault_secrets_app.example.secrets.USER_COGNITO_POOL_ID}"},
        {"name": "USER_COGNITO_DOMAIN", "value": "${data.hcp_vault_secrets_app.example.secrets.USER_COGNITO_DOMAIN}"},
        {"name": "EMAILS_FROM_NAME", "value": "${data.hcp_vault_secrets_app.example.secrets.EMAILS_FROM_NAME}"},
        {"name": "EMAILS_FROM_EMAIL", "value": "${data.hcp_vault_secrets_app.example.secrets.EMAILS_FROM_EMAIL}"},
        {"name": "EMAILS_SECRET_KEY", "value": "${data.hcp_vault_secrets_app.example.secrets.EMAILS_SECRET_KEY}"}
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.api.name}",
          "awslogs-stream-prefix": "ecs",
          "awslogs-region" : "${var.aws_region}"
        }
      }
    }
  ]
  DEFINITION

  lifecycle {
    replace_triggered_by = [
      null_resource.docker_packaging
    ]
  }
}

resource "aws_security_group" "loadbalancer_sg" {
  name        = "${var.image_name}-lb"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.image_name}-lb"
  }

  ingress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "${var.image_name}-instance"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.image_name}-instance"
  }

  ingress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

locals {
  target_groups = [
    "green",
    "blue",
  ]
}

resource "aws_lb_target_group" "ip" {
  lifecycle {
    create_before_destroy = true
  }

  count = length(local.target_groups)

  name        = "${var.image_name}-${element(local.target_groups, count.index)}"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    interval = 15
    healthy_threshold = 2
    matcher = "200,301,302,404"
    path    = "/health_check"
  }
}

resource "aws_lb" "application" {
  name               = "${var.image_name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.loadbalancer_sg.id]
  subnets            = var.vpc_subnet_ids

  enable_deletion_protection = false
}

data "aws_acm_certificate" "issued" {
  domain   = "weblang.ai"
  statuses = ["ISSUED"]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.application.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.issued.arn
  depends_on = [aws_lb_target_group.ip]
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ip[0].arn
  }
  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_ecs_service" "api" {
  name            = "api"
  cluster         = aws_ecs_cluster.foo.id
  task_definition = aws_ecs_task_definition.github_backup.arn
  desired_count   = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type = "FARGATE"

  force_new_deployment = true
  depends_on = [aws_ecs_cluster.foo]

  load_balancer {
    target_group_arn = aws_lb_target_group.ip[0].arn
    container_name   = "api"
    container_port   = 80
  }

  # deployment_controller {
  #   type = "CODE_DEPLOY"
  # }

  lifecycle {
    ignore_changes = [desired_count, load_balancer]
  }

  network_configuration {
    subnets            = var.vpc_subnet_ids
    security_groups = [aws_security_group.instance_sg.id]
    assign_public_ip  = true
  }
}

