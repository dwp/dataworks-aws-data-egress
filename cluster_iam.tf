resource "aws_iam_role" "data_egress_server" {
  name               = "DataEgressServer"
  assume_role_policy = data.aws_iam_policy_document.data_egress_server_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_instance_profile" "data_egress_server" {
  name = "DataEgressServer"
  role = aws_iam_role.data_egress_server.name
}

data "aws_iam_policy_document" "data_egress_server_assume_role" {
  statement {
    sid = "ECSAssumeRole"
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_cloudwatch_log_group" "data_egress_server_logs" {
  name              = "/app/data-egress-server"
  retention_in_days = 180
  tags              = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ec2_for_ssm_attachment" {
  role       = aws_iam_role.data_egress_server.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "data_egress_server_amazon_ec2_readonly_access" {
  role       = aws_iam_role.data_egress_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "data_egress_server_export_certificate_bucket_read" {
  role       = aws_iam_role.data_egress_server.name
  policy_arn = "arn:aws:iam::${local.account[local.environment]}:policy/CertificatesBucketRead"
}

resource "aws_iam_role_policy_attachment" "data_egress_server_ebs_cmk_instance_encrypt_decrypt" {
  role       = aws_iam_role.data_egress_server.name
  policy_arn = "arn:aws:iam::${local.account[local.environment]}:policy/EBSCMKInstanceEncryptDecrypt"
}

resource "aws_iam_role_policy_attachment" "data_egress_server_ecs_cwasp" {
  role       = aws_iam_role.data_egress_server.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "data_egress_cluster_ecs" {
  role       = aws_iam_role.data_egress_server.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_policy" "data_egress_server" {
  name        = "DataEgressServer"
  description = "Custom policy for data egress server"
  policy      = data.aws_iam_policy_document.data_egress_server.json
}

resource "aws_iam_role_policy_attachment" "data_egress_server" {
  role       = aws_iam_role.data_egress_server.name
  policy_arn = aws_iam_policy.data_egress_server.arn
}

data "aws_iam_policy_document" "data_egress_server" {
  statement {
    sid = "AllowDataEgressEC2ToPollSQS"
    actions = [
      # Due to a tf/AWS bug, currently requires SQS to be capitalised.
      "SQS:ChangeMessageVisibility",
      "SQS:DeleteMessage",
      "SQS:ReceiveMessage",
      # When tf/AWS bug fixed, this should work correctly.
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage"
    ]
    resources = [aws_sqs_queue.data_egress.arn]
  }

  statement {
    sid = "AllowDataEgressEC2ToReadDynamoDB"
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:GetItem",
      "dynamodb:GetRecords",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [aws_dynamodb_table.data_egress.arn]
  }

  statement {
    sid    = "CertificateExport"
    effect = "Allow"
    actions = [
      "acm:ExportCertificate",
    ]
    resources = [aws_acm_certificate.data_egress_server.arn]
  }

  statement {
    sid = "PublishedNonSensitiveBucketKMSDecrypt"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = [data.terraform_remote_state.common.outputs.published_nonsensitive_cmk.arn]
  }

  statement {
    sid = "PublishedNonSensitiveBucketRead"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [data.terraform_remote_state.common.outputs.published_nonsensitive.arn]
  }

  statement {
    sid = "PublishedNonSensitiveBucketObjectRead"
    actions = [
      "s3:GetObject"
    ]
    resources = ["${data.terraform_remote_state.common.outputs.published_nonsensitive.arn}/opsmi/*"]
  }

  statement {
    sid = "CloudWatchLogsWrite"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [aws_cloudwatch_log_group.data_egress_server_logs.arn]
  }

}
