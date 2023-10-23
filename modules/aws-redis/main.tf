resource "aws_security_group" "redis_sg" {
  name        = "${var.redis_name}-elasticache"
  vpc_id      = var.vpc_id

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

  tags = {
    Name = "${var.redis_name}-elasticache"
  }
}

resource "aws_elasticache_subnet_group" "redis_private_subnet_group" {
  name        = "${var.redis_name}-redis-subnet"
  description = "redis private subnet"
  subnet_ids  = var.vpc_subnet_ids
}

resource "aws_elasticache_cluster" "redis_instance" {
  cluster_id           = var.redis_name
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t4g.small"
  num_cache_nodes      = 1
  security_group_ids   = [
    aws_security_group.redis_sg.id
  ]
  snapshot_retention_limit = 7
  subnet_group_name = aws_elasticache_subnet_group.redis_private_subnet_group.name
}
