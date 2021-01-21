resource "aws_sqs_queue" "data_egress" {
  name = "data-egress"

  tags = merge(
    local.common_tags,
    {
      Name = "data-egress"
    },
  )
}

resource "aws_dynamodb_table" "data_egress" {
  name           = "data-egress"
  hash_key       = "pipeline_name"
  range_key      = "recipient_name"
  read_capacity  = 20
  write_capacity = 20

  attribute {
    name = "pipeline_name"
    type = "S"
  }

  attribute {
    name = "recipient_name"
    type = "S"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "data-egress"
    },
  )
}

resource "aws_dynamodb_table_item" "opsmi_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "pipeline_name":          {"S": "OpsMI"},
    "recipient_name":         {"S": "OpsMI"},
    "transfer_type":          {"S": "S3"},
    "source_bucket":          {"S": "${data.terraform_remote_state.common.outputs.published_nonsensitive.id}"},
    "source_prefix":          {"S": "opsmi/"},
    "destination_bucket":     {"S": "TBD"},
    "destination_prefix":     {"S": "TBD/"}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "dataworks_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "pipeline_name":          {"S": "data-egress-testing"},
    "recipient_name":         {"S": "DataWorks"},
    "transfer_type":          {"S": "S3"},
    "source_bucket":          {"S": "${data.terraform_remote_state.common.outputs.published_nonsensitive.id}"},
    "source_prefix":          {"S": "dataworks-egress-testing-input/"},
    "destination_bucket":     {"S": "${data.terraform_remote_state.common.outputs.published_nonsensitive.id}"},
    "destination_prefix":     {"S": "data-egress-testing-output/"}
  }
  ITEM
}

resource "aws_sqs_queue_policy" "published_non_sensitive_bucket_notification_policy" {
  # Note - this is a permissive policy (in addition to everything allowed by IAM)
  policy    = data.aws_iam_policy_document.published_non_sensitive_bucket_s3.json
  queue_url = aws_sqs_queue.data_egress.id
}

data "aws_iam_policy_document" "published_non_sensitive_bucket_s3" {

  statement {
    sid       = "AllowPublishedNonSensitiveBucketToSendSQSMessage"
    effect    = "Allow"
    resources = [aws_sqs_queue.data_egress.arn]

    actions = [
      # Due to a tf/AWS bug, currently requires SQS to be capitalised.
      "SQS:SendMessage",
      # When tf/AWS bug fixed, this should work correctly.
      "sqs:SendMessage",
    ]

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [data.terraform_remote_state.common.outputs.published_nonsensitive.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account[local.environment]]
    }
  }
}

resource "aws_acm_certificate" "data_egress_server" {
  certificate_authority_arn = data.terraform_remote_state.certificate_authority.outputs.root_ca.arn
  domain_name               = "${local.data_egress_server_name}.${local.env_prefix[local.environment]}dataworks.dwp.gov.uk"

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.data_egress_server_name
    },
  )
}

data "local_file" "data_egress_server_logrotate_script" {
  filename = "files/data_egress_server.logrotate"
}

resource "aws_s3_bucket_object" "data_egress_server_logrotate_script" {
  bucket  = data.terraform_remote_state.common.outputs.config_bucket.id
  key     = "component/data-egress-server/data-egress-server.logrotate"
  content = data.local_file.data_egress_server_logrotate_script.content

  tags = merge(
    local.common_tags,
    {
      Name = "data-egress-server-logrotate-script"
    },
  )
}

data "local_file" "data_egress_server_cloudwatch_script" {
  filename = "files/data_egress_server_cloudwatch.sh"
}

resource "aws_s3_bucket_object" "data_egress_server_cloudwatch_script" {
  bucket  = data.terraform_remote_state.common.outputs.config_bucket.id
  key     = "component/data-egress-server/data-egress-server-cloudwatch.sh"
  content = data.local_file.data_egress_server_cloudwatch_script.content

  tags = merge(
    local.common_tags,
    {
      Name = "data-egress-server-cloudwatch-script"
    },
  )
}
