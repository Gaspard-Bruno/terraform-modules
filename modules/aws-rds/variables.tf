variable "rds_name" {
  description = "RDS Name"
  type = string
}

variable "initial_db_name" {
  description = "Initial db name"
  type = string
}

variable "vpc_id" {
  description = "Vpc ID"
  type = string
}

variable "office_ip" {
  description = "G+B's Office IP"
  type = string
}

variable "instance_class" {
  description = "DB's instance class"
  type = string
  default = "db.t3.micro"
}

