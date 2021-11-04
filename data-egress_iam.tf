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

    principals {
      identifiers = ["arn:aws:iam::${local.account[local.environment]}:role/DataEgressServer"]
      type        = "AWS"
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
    resources = ["arn:aws:s3:::${local.opsmi[local.environment].bucket_name}/*", "arn:aws:s3:::${local.opsmi[local.environment].bucket_name}"]
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
    sid = "OneServiceBucketObjectPut"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = ["arn:aws:s3:::${local.oneservice[local.environment].bucket_name}/*", "arn:aws:s3:::${local.oneservice[local.environment].bucket_name}"]
  }

  statement {
    sid = "OneServiceBucketKMSDecrypt"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = ["arn:aws:kms:eu-west-2:${local.oneservice[local.environment].account_id}:key/*"]
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
    resources = [
      data.terraform_remote_state.common.outputs.data_egress_sqs.arn
    ]
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
    sid = "PublishedBucketKMSDecrypt"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [data.terraform_remote_state.common.outputs.published_bucket_cmk.arn]
  }

  statement {
    sid = "PublishedBucketRead"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [data.terraform_remote_state.common.outputs.published_bucket.arn, "arn:aws:s3:::${local.opsmi[local.environment].bucket_name}"]
  }

  statement {
    sid = "PublishedBucketObjectRead"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${data.terraform_remote_state.common.outputs.published_bucket.arn}/opsmi/*",
      "${data.terraform_remote_state.common.outputs.published_bucket.arn}/dataegress/cbol-report/*",
      "${data.terraform_remote_state.common.outputs.published_bucket.arn}/dataworks-egress-testing-input/*",
      "${data.terraform_remote_state.common.outputs.published_bucket.arn}/dataegress/sas/*",
      "${data.terraform_remote_state.common.outputs.published_bucket.arn}/rtg-pdm-exports/*",
      "${data.terraform_remote_state.common.outputs.published_bucket.arn}/ucdata/*",
      "${data.terraform_remote_state.common.outputs.published_bucket.arn}/businessdata/*",
      "${data.terraform_remote_state.common.outputs.published_bucket.arn}/dataegress/dwh/*",
      "${data.terraform_remote_state.common.outputs.published_bucket.arn}/dataegress/oneservice/*",
      "${data.terraform_remote_state.common.outputs.published_bucket.arn}/common-model-inputs/*",
      "${data.terraform_remote_state.common.outputs.published_bucket.arn}/dataegress/ers/*"
    ]
  }

  statement {
    sid = "PublishedBucketTestingObjectPut"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${data.terraform_remote_state.common.outputs.published_bucket.arn}/data-egress-testing-output/*",
      "${data.terraform_remote_state.common.outputs.published_bucket.arn}/dataworks-egress-testing-input/*"
    ]
  }

  # RTG Temporary bucket
  statement {
    sid = "RTGTempBucketGetandPutObject"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.rtg_temp.arn}/*"]
  }

  statement {
    sid = "RTGTempBucketList"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = ["${aws_s3_bucket.rtg_temp.arn}"]
  }

  statement {
    sid = "RTGTempBucketKMSEncrypt"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.rtg_temp_bucket_cmk.arn]
  }

  statement {
    sid = "CompactionBucketObjectGet"
    actions = [
      "s3:GetObject"
    ]
    resources = ["${data.terraform_remote_state.internal_compute.outputs.compaction_bucket.arn}/*"]
  }

  statement {
    sid = "CompactionBucketRead"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [data.terraform_remote_state.internal_compute.outputs.compaction_bucket.arn]
  }

  statement {
    sid = "CompactionBucketKMSDecrypt"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [data.terraform_remote_state.internal_compute.outputs.compaction_bucket_cmk.arn]
  }

  statement {
    sid       = "DataEgressGetCAMgmtCertS3"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${data.terraform_remote_state.mgmt_ca.outputs.public_cert_bucket.arn}/*"]
  }

  statement {
    sid       = "DataEgressAssumeRTGRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [local.rtg[local.environment].rtg_role_arn]
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
