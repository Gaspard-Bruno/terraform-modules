variable "redis_name" {
  description = "Redis Name"
  type = string
}

variable "vpc_id" {
  description = "Vpc ID"
  type = string
}

variable "vpc_subnet_ids" {
  description = "Vpc subnet IDs"
  type = list
}
