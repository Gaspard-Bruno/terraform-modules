variable "user_names" {
  description = "List of User Names"
  type = list
}

variable "policy_name" {
  description = "Policy Name"
  type = string
}

variable "statements" {
  description = "Policy Name"
  # type = set
  type = set(object({
      actions   = list(string)
      effect    = string
      resources = list(string)
    }))
}
