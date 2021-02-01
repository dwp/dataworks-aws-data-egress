resource "aws_iam_role" "data_egress_server_task" {
  name               = "DataEgressServer"
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

data "aws_iam_policy_document" "data_egress_server_task" {

  statement {
    sid = "OpsMIBucketObjectPut"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = ["arn:aws:s3:::${local.opsmi[local.environment].bucket_name}/*"]
  }

  statement {
    sid = "OpsMIBucketKMSDecrypt"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = ["arn:aws:kms:eu-west-2:${local.opsmi[local.environment].account_id}:key/*"]
  }
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
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes"
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
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
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
    resources = ["${data.terraform_remote_state.common.outputs.published_nonsensitive.arn}/opsmi/*", "${data.terraform_remote_state.common.outputs.published_nonsensitive.arn}/dataworks-egress-testing-input/*"]
  }

  statement {
    sid = "PublishedNonSensitiveBucketObjectPut"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${data.terraform_remote_state.common.outputs.published_nonsensitive.arn}/data-egress-testing-output/*",
      "${data.terraform_remote_state.common.outputs.published_nonsensitive.arn}/dataworks-egress-testing-input/*"
    ]
  }
  statement {
    sid       = "DataEgressGetCAMgmtCertS3"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${data.terraform_remote_state.mgmt_ca.outputs.public_cert_bucket.arn}/*"]
  }

}

resource "aws_iam_policy" "data_egress_server_task" {
  name        = "DataEgressServer"
  description = "Custom policy for data egress server"
  policy      = data.aws_iam_policy_document.data_egress_server_task.json
}
resource "aws_iam_role_policy_attachment" "data_egress_server" {
  role       = aws_iam_role.data_egress_server_task.name
  policy_arn = aws_iam_policy.data_egress_server_task.arn
}

resource "aws_iam_role_policy_attachment" "data_egress_server_export_certificate_bucket_read" {
  role       = aws_iam_role.data_egress_server_task.name
  policy_arn = "arn:aws:iam::${local.account[local.environment]}:policy/CertificatesBucketRead"
}

resource "aws_iam_role_policy_attachment" "data_egress_server_ebs_cmk_instance_encrypt_decrypt" {
  role       = aws_iam_role.data_egress_server_task.name
  policy_arn = "arn:aws:iam::${local.account[local.environment]}:policy/EBSCMKInstanceEncryptDecrypt"
}
