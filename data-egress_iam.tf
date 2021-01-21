resource "aws_iam_role" "data_egress_server_task" {
  name               = "data_egress_server_task"
  assume_role_policy = data.aws_iam_policy_document.data_egress_server_task_assume_role.json
}

data "aws_iam_policy_document" "data_egress_server_task_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
