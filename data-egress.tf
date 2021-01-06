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

resource "aws_security_group" "data_egress_server" {
  name        = "data_egress_server"
  description = "Control access to and from data egress server"
  vpc_id      = data.terraform_remote_state.aws_sdx.outputs.vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      "Name" = local.data_egress_server_name
    }
  )
}

resource "aws_autoscaling_group" "data_egress_server" {
  name_prefix               = "${aws_launch_template.data_egress_server.name}-lt_ver${aws_launch_template.data_egress_server.latest_version}_"
  min_size                  = local.data_egress_server_asg_min[local.environment]
  desired_capacity          = local.data_egress_server_asg_desired[local.environment]
  max_size                  = local.data_egress_server_asg_max[local.environment]
  health_check_grace_period = 600
  health_check_type         = "EC2"
  force_delete              = true
  vpc_zone_identifier       = data.terraform_remote_state.aws_sdx.outputs.subnet_sdx_connectivity.*.id

  launch_template {
    id      = aws_launch_template.data_egress_server.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = local.data_egress_server_tags_asg

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

resource "aws_launch_template" "data_egress_server" {
  name_prefix            = "data_egress_server_"
  image_id               = var.al2_hardened_ami_id
  instance_type          = var.data_egress_server_ec2_instance_type[local.environment]
  vpc_security_group_ids = [aws_security_group.data_egress_server.id]
  user_data = base64encode(templatefile("files/data_egress_server_userdata.tpl", {
    environment_name                                 = local.environment
    acm_cert_arn                                     = aws_acm_certificate.data_egress_server.arn
    truststore_aliases                               = join(",", var.truststore_aliases)
    truststore_certs                                 = "s3://${local.env_certificate_bucket}/ca_certificates/dataworks/dataworks_root_ca.pem,s3://${data.terraform_remote_state.mgmt_ca.outputs.public_cert_bucket.id}/ca_certificates/dataworks/dataworks_root_ca.pem"
    private_key_alias                                = "data-egress"
    internet_proxy                                   = data.terraform_remote_state.aws_sdx.outputs.internet_proxy.host
    non_proxied_endpoints                            = join(",", data.terraform_remote_state.aws_sdx.outputs.vpc.no_proxy_list)
    dks_fqdn                                         = local.dks_fqdn
    cwa_namespace                                    = local.cw_data_egress_server_agent_namespace
    cwa_metrics_collection_interval                  = local.cw_agent_metrics_collection_interval
    cwa_cpu_metrics_collection_interval              = local.cw_agent_cpu_metrics_collection_interval
    cwa_disk_measurement_metrics_collection_interval = local.cw_agent_disk_measurement_metrics_collection_interval
    cwa_disk_io_metrics_collection_interval          = local.cw_agent_disk_io_metrics_collection_interval
    cwa_mem_metrics_collection_interval              = local.cw_agent_mem_metrics_collection_interval
    cwa_netstat_metrics_collection_interval          = local.cw_agent_netstat_metrics_collection_interval
    cwa_log_group_name                               = aws_cloudwatch_log_group.data_egress_server_logs.name
    s3_scripts_bucket                                = data.terraform_remote_state.common.outputs.config_bucket.id
    s3_file_data_egress_server_logrotate             = aws_s3_bucket_object.data_egress_server_logrotate_script.id
    s3_file_data_egress_server_logrotate_md5         = md5(data.local_file.data_egress_server_logrotate_script.content)
    s3_file_data_egress_server_cloudwatch_sh         = aws_s3_bucket_object.data_egress_server_cloudwatch_script.id
    s3_file_data_egress_server_cloudwatch_sh_md5     = md5(data.local_file.data_egress_server_cloudwatch_script.content)
  }))
  instance_initiated_shutdown_behavior = "terminate"

  iam_instance_profile {
    arn = aws_iam_instance_profile.data_egress_server.arn
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.data_egress_server_ebs_volume_size[local.environment]
      volume_type           = var.data_egress_server_ebs_volume_type[local.environment]
      delete_on_termination = true
      encrypted             = true
    }
  }

  monitoring {
    enabled = true
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "data_egress_server"
    }
  )

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.common_tags,
      {
        Name         = "data_egress_server"
        Application  = "data_egress_server"
        Persistence  = "Ignore"
        AutoShutdown = "False"
        SSMEnabled   = local.data_egress_server_ssmenabled[local.environment]
      }
    )
  }

}

data "aws_iam_policy_document" "data_egress_server_assume_role" {
  statement {
    sid = "EC2AssumeRole"
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}


resource "aws_iam_role" "data_egress_server" {
  name               = "DataEgressServer"
  assume_role_policy = data.aws_iam_policy_document.data_egress_server_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_instance_profile" "data_egress_server" {
  name = "DataEgressServer"
  role = aws_iam_role.data_egress_server.name
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

resource "aws_iam_role_policy_attachment" "data_egress_server_amazon_ssm_managed_instance_core" {
  role       = aws_iam_role.data_egress_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
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

resource "aws_iam_policy" "data_egress_server" {
  name        = "DataEgressServer"
  description = "Custom policy for data egress server"
  policy      = data.aws_iam_policy_document.data_egress_server.json
}

resource "aws_iam_role_policy_attachment" "data_egress_server" {
  role       = aws_iam_role.data_egress_server.name
  policy_arn = aws_iam_policy.data_egress_server.arn
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

resource "aws_security_group_rule" "data_egress_server_s3" {
  description       = "Allow data egress server to reach S3"
  type              = "egress"
  prefix_list_ids   = [data.terraform_remote_state.aws_sdx.outputs.vpc.prefix_list_ids.s3]
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.data_egress_server.id
}

resource "aws_security_group_rule" "data_egress_server_dynamodb" {
  description       = "Allow data egress server to reach DynamoDB"
  type              = "egress"
  prefix_list_ids   = [data.terraform_remote_state.aws_sdx.outputs.vpc.prefix_list_ids.dynamodb]
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.data_egress_server.id
}

resource "aws_security_group_rule" "egress_data_egress_server_internet" {
  description              = "Allow data egress server access to Internet Proxy (for ACM-PCA)"
  type                     = "egress"
  source_security_group_id = data.terraform_remote_state.aws_sdx.outputs.internet_proxy.sg
  protocol                 = "tcp"
  from_port                = 3128
  to_port                  = 3128
  security_group_id        = aws_security_group.data_egress_server.id
}

resource "aws_security_group_rule" "ingress_data_egress_server_internet" {
  description              = "Allow data egress server access to Internet Proxy (for ACM-PCA)"
  type                     = "ingress"
  source_security_group_id = aws_security_group.data_egress_server.id
  protocol                 = "tcp"
  from_port                = 3128
  to_port                  = 3128
  security_group_id        = data.terraform_remote_state.aws_sdx.outputs.internet_proxy.sg
}

resource "aws_security_group_rule" "egress_data_egress_server_vpc_endpoint" {
  description              = "Allow data egress server access to VPC endpoints"
  type                     = "egress"
  source_security_group_id = data.terraform_remote_state.aws_sdx.outputs.vpc.interface_vpce_sg_id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  security_group_id        = aws_security_group.data_egress_server.id
}

resource "aws_security_group_rule" "ingress_data_egress_server_vpc_endpoint" {
  description              = "Allow data egress server access to VPC endpoints"
  type                     = "ingress"
  source_security_group_id = aws_security_group.data_egress_server.id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  security_group_id        = data.terraform_remote_state.aws_sdx.outputs.vpc.interface_vpce_sg_id
}

resource "aws_security_group_rule" "data_egress_dks" {
  description       = "Allow outbound requests to DKS"
  type              = "egress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  cidr_blocks       = data.terraform_remote_state.crypto.outputs.dks_subnet.cidr_blocks
  security_group_id = aws_security_group.data_egress_server.id
}

//Looks like there already exists another rule to allow this CIDR block and below ingress rule is failing because of a TF bug https://github.com/hashicorp/terraform/pull/2376
//resource "aws_security_group_rule" "data_ingress_dks" {
//  provider          = aws.management-crypto
//  description       = "Allow inbound requests to DKS from data egress server"
//  type              = "ingress"
//  from_port         = 8443
//  to_port           = 8443
//  protocol          = "tcp"
//  cidr_blocks       = aws_subnet.sdx_connectivity.*.cidr_block
//  security_group_id = data.terraform_remote_state.crypto.outputs.dks_sg_id[local.environment]
//}
