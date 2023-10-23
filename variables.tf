variable "project_name" {
  description = "Name of project"
  type = string
  default = "gbaccesscontrol"
}

variable "office_ip" {
  description = "IP of G+B  Office"
  type = string
  default = "195.23.194.0/24"
}

variable "aws_access_key_id" {
  # type = string
  # default = ""
}

variable "aws_secret_access_key" {
  # type = string
  # default = ""
}

variable "aws_region" {
  # type = string
  # default = ""
}

variable "aws_account_id" {
  # type = string
  # default = ""
}
