variable "user_name" {
  description = "UserName"
  type = string
}

variable "policy_arns" {
  description = "PolicyArns"
  type = set(string)
  default = []
}

variable "custom_policies" {
  description = "CustomPolicies"
  type = set(object({
    name      = string
    statements = list(object({
      actions   = list(string)
      effect    = string
      resources = list(string)
    }))
  }))
  default = []
}

