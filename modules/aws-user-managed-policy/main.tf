data "aws_iam_policy" "readonlyaccess" {
  name = var.policy_name
}

resource "aws_iam_policy_attachment" "policy_arn" {
  name       = var.policy_name
  users      = var.user_names
  policy_arn = data.aws_iam_policy.readonlyaccess.arn
}
