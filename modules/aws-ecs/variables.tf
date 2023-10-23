variable "cluster_name" {
  description = "Cluster Name"
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

variable "task_name" {
  description = "Task Definition name"
  type = string
}

variable "task_cpu" {
  description = "Task Definition name"
  type = number
}

variable "task_memory" {
  description = "Task Definition name"
  type = number
}

# variable "container_name" {
#   description = "Task Definition name"
#   type = string
# }

# variable "container_image" {
#   description = "Task Definition name"
#   type = string
# }

variable "image_name" {
  type = string
}

variable "aws_access_key_id" {
  type = string
}

variable "aws_secret_access_key" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  type = string
}
