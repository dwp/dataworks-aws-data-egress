resource "aws_dynamodb_table" "data_egress" {
  name           = "data-egress"
  hash_key       = "source_prefix"
  range_key      = "pipeline_name"
  read_capacity  = 20
  write_capacity = 20

  attribute {
    name = "source_prefix"
    type = "S"
  }

  attribute {
    name = "pipeline_name"
    type = "S"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "data-egress"
    },
  )
}

resource "aws_dynamodb_table_item" "rtg_pdm_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  for_each = { for configitem in local.rtg_pdm_queries : configitem.source_prefix => configitem }

  item = <<ITEM
  {
    "source_prefix":                {"S":     "${each.value.source_prefix}"},
    "pipeline_name":                {"S":     "RTG_S3"},
    "recipient_name":               {"S":     "RTG"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.rtg[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "${each.value.destination_prefix}"},
    "decrypt":                      {"bool":   ${each.value.decrypt}},
    "rewrap_datakey":               {"bool":   ${each.value.rewrap_datakey}},
    "encrypting_key_ssm_parm_name": {"S":     "${each.value.encrypting_key_ssm_parm_name}"},
    "role_arn":                     {"S":     "${local.rtg[local.environment].rtg_role_arn}"}

  }
  ITEM
}


resource "aws_dynamodb_table_item" "rtg_incremental_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  for_each = { for configitem in local.rtg_incremental_collections : configitem.source_prefix => configitem }

  item = <<ITEM
  {
    "source_prefix":                {"S":     "${each.value.source_prefix}"},
    "pipeline_name":                {"S":     "RTG_S3"},
    "recipient_name":               {"S":     "RTG"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.internal_compute.outputs.compaction_bucket.id}"},
    "destination_bucket":           {"S":     "${local.rtg[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "${each.value.destination_prefix}"},
    "decrypt":                      {"bool":   ${each.value.decrypt}},
    "rewrap_datakey":               {"bool":   ${each.value.rewrap_datakey}},
    "encrypting_key_ssm_parm_name": {"S":     "${each.value.encrypting_key_ssm_parm_name}"},
    "role_arn":                     {"S":     "${local.rtg[local.environment].rtg_role_arn}"}

  }
  ITEM
}

resource "aws_dynamodb_table_item" "rtg_full_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  for_each = { for configitem in local.rtg_full_collections : configitem.source_prefix => configitem }

  item = <<ITEM
  {
    "source_prefix":                {"S":     "${each.value.source_prefix}"},
    "pipeline_name":                {"S":     "RTG_S3"},
    "recipient_name":               {"S":     "RTG"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.internal_compute.outputs.compaction_bucket.id}"},
    "destination_bucket":           {"S":     "${local.rtg[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "${each.value.destination_prefix}"},
    "decrypt":                      {"bool":   ${each.value.decrypt}},
    "rewrap_datakey":               {"bool":   ${each.value.rewrap_datakey}},
    "encrypting_key_ssm_parm_name": {"S":     "${each.value.encrypting_key_ssm_parm_name}"},
    "role_arn":                     {"S":     "${local.rtg[local.environment].rtg_role_arn}"}

  }
  ITEM
}


resource "aws_dynamodb_table_item" "opsmi_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "opsmi/"},
    "pipeline_name":                {"S":     "OpsMI"},
    "recipient_name":               {"S":     "OpsMI"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.opsmi[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "cbol_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/cbol-report/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":     "CBOL"},
    "recipient_name":               {"S":     "CBOL"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.opsmi[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "cbol/$TODAYS_DATE/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "dataworks_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "dataworks-egress-testing-input/"},
    "pipeline_name":                {"S":    "data-egress-testing"},
    "recipient_name":               {"S":    "DataWorks"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_prefix":           {"S":    "data-egress-testing-output/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "housing_SAS_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "dataegress/sas/ucs_housing/export/*"},
    "pipeline_name":                {"S":    "DWX-SAS-SFT01"},
    "recipient_name":               {"S":    "Housing"},
    "transfer_type":                {"S":    "SFT"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_prefix":           {"S":    "/data-egress/sas/"},
    "decrypt":                      {"bool": false},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
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
