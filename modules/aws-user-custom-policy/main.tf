data "aws_iam_policy_document" "policy" {
  dynamic "statement" {
    for_each = var.statements
    content {
      effect = statement.value["effect"]
      resources = statement.value["resources"]
      actions = statement.value["actions"]
    }
  }
}

resource "aws_iam_policy" "policy" {
  name        = var.policy_name
  policy      = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_policy_attachment" "policy_arn" {
  name       = var.policy_name
  users      = var.user_names
  policy_arn = aws_iam_policy.policy.arn
}
