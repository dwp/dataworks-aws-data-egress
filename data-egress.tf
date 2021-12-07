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

resource "aws_dynamodb_table_item" "pdm_rtg_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  for_each = { for configitem in local.rtg_pdm_queries : configitem.source_prefix => configitem }

  item = <<ITEM
  {
    "source_prefix":                {"S":     "${each.value.source_prefix}"},
    "pipeline_name":                {"S":     "PDM_RTG"},
    "recipient_name":               {"S":     "RTG"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.pdm_rtg[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "${each.value.destination_prefix}"},
    "decrypt":                      {"bool":   ${each.value.decrypt}},
    "rewrap_datakey":               {"bool":   ${each.value.rewrap_datakey}},
    "encrypting_key_ssm_parm_name": {"S":     "${each.value.encrypting_key_ssm_parm_name}"},
    "role_arn":                     {"S":     "${local.pdm_rtg[local.environment].rtg_role_arn}"}

  }
  ITEM
}

resource "aws_dynamodb_table_item" "htme_incremental_rtg_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  for_each = { for configitem in local.rtg_incremental_collections : configitem.source_prefix => configitem }

  item = <<ITEM
  {
    "source_prefix":                {"S":     "${each.value.source_prefix}-"},
    "pipeline_name":                {"S":     "HTME_RTG_Incremental"},
    "recipient_name":               {"S":     "RTG"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.internal_compute.outputs.compaction_bucket.id}"},
    "destination_bucket":           {"S":     "${local.htme_incr_rtg[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "${each.value.destination_prefix}"},
    "decrypt":                      {"bool":   ${each.value.decrypt}},
    "rewrap_datakey":               {"bool":   ${each.value.rewrap_datakey}},
    "encrypting_key_ssm_parm_name": {"S":     "${each.value.encrypting_key_ssm_parm_name}"},
    "manifest_file_name":           {"S":     "${each.value.manifest_file_name}"},
    "manifest_file_encryption":     {"S":     "${each.value.manifest_file_encryption}"}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "htme_full_rtg_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  for_each = { for configitem in local.rtg_full_collections : configitem.source_prefix => configitem }

  item = <<ITEM
  {
    "source_prefix":                {"S":     "${each.value.source_prefix}-"},
    "pipeline_name":                {"S":     "HTME_RTG_Full"},
    "recipient_name":               {"S":     "RTG"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.internal_compute.outputs.compaction_bucket.id}"},
    "destination_bucket":           {"S":     "${local.htme_full_rtg[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "${each.value.destination_prefix}"},
    "decrypt":                      {"bool":   ${each.value.decrypt}},
    "rewrap_datakey":               {"bool":   ${each.value.rewrap_datakey}},
    "encrypting_key_ssm_parm_name": {"S":     "${each.value.encrypting_key_ssm_parm_name}"},
    "manifest_file_name":           {"S":     "${each.value.manifest_file_name}"},
    "manifest_file_encryption":     {"S":     "${each.value.manifest_file_encryption}"}
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

resource "aws_dynamodb_table_item" "oneservice_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/oneservice/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":     "ONESERVICE"},
    "recipient_name":               {"S":     "ONESERVICE"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "oneservice/$TODAYS_DATE/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}



resource "aws_dynamodb_table_item" "ers_cyidb_alldata_weeks_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/cyi/$TODAYS_DATE/cyidb_alldata_weeks/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "cyi/cyidb_alldata_weeks/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}


resource "aws_dynamodb_table_item" "ers_cyidb_alldata_date_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/cyi/$TODAYS_DATE/cyidb_alldata_date/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "cyi/cyidb_alldata_date/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_cyidb_alldata_totals_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/cyi/$TODAYS_DATE/cyidb_alldata_totals/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "cyi/cyidb_alldata_totals/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_cyidb_enter_byhour_pct_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/cyi/$TODAYS_DATE/cyidb_enter_byhour_pct/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "cyi/cyidb_enter_byhour_pct/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_cyidb_help_messages_pct_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/cyi/$TODAYS_DATE/cyidb_help_messages_pct/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "cyi/cyidb_help_messages_pct/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_govverify_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/goverify/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "verifyweekly/weeklysite/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}


resource "aws_dynamodb_table_item" "ers_wbwar_newidvs_bwa_by_week_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/bwa/$TODAYS_DATE/wbwar_newidvs_bwa_by_week/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "bwa/wbwar_newidvs_bwa_by_week/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}


resource "aws_dynamodb_table_item" "ers_wbwar_newidvs_bwa_byidv_week_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/bwa/$TODAYS_DATE/wbwar_newidvs_bwa_byidv_week/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "bwa/wbwar_newidvs_bwa_byidv_week/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}


resource "aws_dynamodb_table_item" "ers_wbwar_cocs_bwa_by_week_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/bwa/$TODAYS_DATE/wbwar_cocs_bwa_by_week/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "bwa/wbwar_cocs_bwa_by_week/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}


resource "aws_dynamodb_table_item" "ers_wbwar_bwa_all_calls_by_week_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/bwa/$TODAYS_DATE/wbwar_bwa_all_calls_by_week/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "bwa/wbwar_bwa_all_calls_by_week/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}


resource "aws_dynamodb_table_item" "ers_wbwar_bwa_all_calls_by_date_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/bwa/$TODAYS_DATE/wbwar_bwa_all_calls_by_date/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "bwa/wbwar_bwa_all_calls_by_date/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}



resource "aws_dynamodb_table_item" "ers_wdr_decs_report_all_data_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/weekly_declarations/$TODAYS_DATE/wdr_decs_report_all_data/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "weekly_declarations/wdr_decs_report_all_data/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}


resource "aws_dynamodb_table_item" "ers_wdr_decs_report_4wks_summary_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/weekly_declarations/$TODAYS_DATE/wdr_decs_report_4wks_summary/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "weekly_declarations/wdr_decs_report_4wks_summary/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}


resource "aws_dynamodb_table_item" "ers_wdr_ni_decs_report_all_data_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/weekly_declarations_ni/$TODAYS_DATE/wdr_ni_decs_report_all_data/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "weekly_declarations_ni/wdr_ni_decs_report_all_data/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}


resource "aws_dynamodb_table_item" "ers_wdr_ni_decs_report_4wks_summary_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/weekly_declarations_ni/$TODAYS_DATE/wdr_ni_decs_report_4wks_summary/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "weekly_declarations_ni/wdr_ni_decs_report_4wks_summary/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_wdr_ni_decs_report_site_data_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/weekly_declarations_ni/$TODAYS_DATE/wdr_ni_decs_report_site_data/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "weekly_declarations_ni/wdr_ni_decs_report_site_data/"},
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
    "source_prefix":                {"S":    "dataegress/sas/ucs_housing/export/$TODAYS_DATE/*"},
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

resource "aws_dynamodb_table_item" "data_warehouse_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "dataegress/dwh/*"},
    "pipeline_name":                {"S":    "DWH-Transform-Json"},
    "recipient_name":               {"S":    "DataWarehouse"},
    "transfer_type":                {"S":    "SFT"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_prefix":           {"S":    "/data-egress/warehouse/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "natstats_SAS_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "dataegress/sas/uc_natstats/export/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "DWX-SAS-SFT02"},
    "recipient_name":               {"S":    "NatStats"},
    "transfer_type":                {"S":    "SFT"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_prefix":           {"S":    "/data-egress/sas/"},
    "decrypt":                      {"bool": false},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "htme_incremental_ris_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  for_each = toset([for ris_collection in local.ris_collections : ris_collection if ris_collection != "NOT_SET"])

  item = <<ITEM
  {
    "source_prefix":                {"S":     "businessdata/mongo/ucdata/$TODAYS_DATE/incremental/${each.key}-*"},
    "pipeline_name":                {"S":     "RIS_SFT"},
    "recipient_name":               {"S":     "DSP"},
    "transfer_type":                {"S":     "SFT"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.internal_compute.outputs.htme_s3_bucket.id}"},
    "destination_prefix":           {"S":     "/data-egress/RIS" },
    "decrypt":                      {"bool":  true},
    "rewrap_datakey":               {"bool":  false},
    "control_file_prefix":          {"S":     "${each.key}-$TODAYS_DATE.control"},
    "timestamp_files":              {"bool":  true},
    "encrypting_key_ssm_parm_name": {"S":     ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "pdm_jsons_ris_data_egress" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "common-model-inputs/data/site/*"},
    "pipeline_name":                {"S":     "RIS_SFT"},
    "recipient_name":               {"S":     "DSP"},
    "transfer_type":                {"S":     "SFT"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_prefix":           {"S":     "/data-egress/RIS" },
    "decrypt":                      {"bool":  true},
    "rewrap_datakey":               {"bool":  false},
    "control_file_prefix":          {"S":     "initial-organisation-files-$TODAYS_DATE.control"},
    "timestamp_files":              {"bool":  true},
    "encrypting_key_ssm_parm_name": {"S":     ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "sas_extracts_analyst_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/sas/analyst_data/export/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":     "SAS_ANALYST_SFT"},
    "recipient_name":               {"S":     "SAS"},
    "transfer_type":                {"S":     "SFT"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_prefix":           {"S":     "/data-egress/sas/"},
    "decrypt":                      {"bool":   false},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "sas_extracts_health_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/sas/health/export/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":     "SAS_HEALTH_SFT"},
    "recipient_name":               {"S":     "SAS"},
    "transfer_type":                {"S":     "SFT"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_prefix":           {"S":     "/data-egress/sas/"},
    "decrypt":                      {"bool":   false},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "best_start_grant_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "dataegress/best-start/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "BEST-START-SFT"},
    "recipient_name":               {"S":    "BestStart"},
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
