resource "aws_iam_role" "sft_agent_task" {
  name               = "SFTAgentTask"
  assume_role_policy = data.aws_iam_policy_document.sft_agent_task_assume_role.json
}

data "aws_iam_policy_document" "sft_agent_task_assume_role" {
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

data "aws_iam_policy_document" "sft_agent_task" {

  statement {
    sid = "PullSFTAgentImageECR"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = [data.terraform_remote_state.management.outputs.sft_agent_ecr_repository.arn]
  }

  statement {
    sid = "PullSFTAgentConfigS3"
    actions = [
      "s3:GetObject"
    ]
    resources = ["${data.terraform_remote_state.common.outputs.config_bucket.arn}/${local.sft_agent_config_s3_prefix}"]
  }

}

resource "aws_iam_policy" "sft_agent_task" {
  name        = "SFTAgentTask"
  description = "Custom policy for the sft agent task"
  policy      = data.aws_iam_policy_document.sft_agent_task.json
}
resource "aws_iam_role_policy_attachment" "sft_agent" {
  role       = aws_iam_role.sft_agent_task.name
  policy_arn = aws_iam_policy.sft_agent_task.arn
}

