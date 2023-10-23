resource "aws_iam_user" "user" {
  name      = var.user_name
}

resource "aws_iam_access_key" "user_access_key" {
  user    = aws_iam_user.user.name
}

module "aws-user-managed-policy" {
  source = "../aws-user-managed-policy"

  # for_each    = var.policy_arns == null ? [] : var.policy_arns
  for_each    = var.policy_arns

  user_names  = [aws_iam_user.user.name]
  policy_name = each.key
}

module "aws-user-custom-policy" {
  source = "../aws-user-custom-policy"

  # for_each = var.custom_policies == null ? [] : var.custom_policies

  for_each = {
    for index, policy in var.custom_policies:
    policy.name => policy
  }

  user_names   = [aws_iam_user.user.name]
  policy_name  = each.value.name
  statements   = toset(each.value.statements)
}
