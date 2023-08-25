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

  for_each = nonsensitive({ for configitem in local.rtg_pdm_queries : configitem.source_prefix => configitem })

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

# resource "aws_dynamodb_table_item" "htme_incremental_rtg_data_egress_config" {
#   table_name = aws_dynamodb_table.data_egress.name
#   hash_key   = aws_dynamodb_table.data_egress.hash_key
#   range_key  = aws_dynamodb_table.data_egress.range_key

#   for_each = { for configitem in local.rtg_incremental_collections : configitem.source_prefix => configitem }

#   item = <<ITEM
#   {
#     "source_prefix":                {"S":     "${each.value.source_prefix}-"},
#     "pipeline_name":                {"S":     "HTME_RTG_Incremental"},
#     "recipient_name":               {"S":     "RTG"},
#     "transfer_type":                {"S":     "S3"},
#     "source_bucket":                {"S":     "${data.terraform_remote_state.internal_compute.outputs.compaction_bucket.id}"},
#     "destination_bucket":           {"S":     "${local.htme_incr_rtg[local.environment].bucket_name}"},
#     "destination_prefix":           {"S":     "${each.value.destination_prefix}"},
#     "decrypt":                      {"bool":   ${each.value.decrypt}},
#     "rewrap_datakey":               {"bool":   ${each.value.rewrap_datakey}},
#     "encrypting_key_ssm_parm_name": {"S":     "${each.value.encrypting_key_ssm_parm_name}"},
#     "manifest_file_name":           {"S":     "${each.value.manifest_file_name}"},
#     "manifest_file_encryption":     {"S":     "${each.value.manifest_file_encryption}"},
#     "role_arn":                     {"S":     "${local.pdm_rtg[local.environment].rtg_role_arn}"}
#   }
#   ITEM
# }

# resource "aws_dynamodb_table_item" "htme_full_rtg_data_egress_config" {
#   table_name = aws_dynamodb_table.data_egress.name
#   hash_key   = aws_dynamodb_table.data_egress.hash_key
#   range_key  = aws_dynamodb_table.data_egress.range_key

#   for_each = { for configitem in local.rtg_full_collections : configitem.source_prefix => configitem }

#   item = <<ITEM
#   {
#     "source_prefix":                {"S":     "${each.value.source_prefix}-"},
#     "pipeline_name":                {"S":     "HTME_RTG_Full"},
#     "recipient_name":               {"S":     "RTG"},
#     "transfer_type":                {"S":     "S3"},
#     "source_bucket":                {"S":     "${data.terraform_remote_state.internal_compute.outputs.compaction_bucket.id}"},
#     "destination_bucket":           {"S":     "${local.htme_full_rtg[local.environment].bucket_name}"},
#     "destination_prefix":           {"S":     "${each.value.destination_prefix}"},
#     "decrypt":                      {"bool":   ${each.value.decrypt}},
#     "rewrap_datakey":               {"bool":   ${each.value.rewrap_datakey}},
#     "encrypting_key_ssm_parm_name": {"S":     "${each.value.encrypting_key_ssm_parm_name}"},
#     "manifest_file_name":           {"S":     "${each.value.manifest_file_name}"},
#     "manifest_file_encryption":     {"S":     "${each.value.manifest_file_encryption}"},
#     "role_arn":                     {"S":     "${local.pdm_rtg[local.environment].rtg_role_arn}"}
#   }
#   ITEM
# }

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

resource "aws_dynamodb_table_item" "RIS_DSP_Manual_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/RIS_DSP_Manual/*"},
    "pipeline_name":                {"S":     "RIS_DSP_Manual"},
    "recipient_name":               {"S":     "DSP"},
    "transfer_type":                {"S":     "SFT"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_prefix":           {"S":     "/data-egress/RIS"},
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
    "destination_prefix":           {"S":     "ucds/cyi/weeks/"},
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
    "destination_prefix":           {"S":     "ucds/cyi/dates/"},
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
    "destination_prefix":           {"S":     "ucds/cyi/totals/"},
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
    "destination_prefix":           {"S":     "ucds/cyi/hours/"},
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
    "destination_prefix":           {"S":     "ucds/cyi/help_messages/"},
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
    "destination_prefix":           {"S":     "ucds/bwa/bwa_newidvs_summary_byweek/"},
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
    "destination_prefix":           {"S":     "ucds/bwa/bwa_newidvs_idvmethod_byweek/"},
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
    "destination_prefix":           {"S":     "ucds/bwa/bwa_cocs_byweek/"},
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
    "destination_prefix":           {"S":     "ucds/bwa/bwa_allcalls_byweek/"},
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
    "destination_prefix":           {"S":     "ucds/bwa/bwa_allcalls_bydate/"},
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
    "destination_prefix":           {"S":     "ucds/weekly-declarations/weekly-decs-allweeks/"},
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
    "destination_prefix":           {"S":     "ucds/weekly-declarations/weekly-decs-4wks/"},
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
    "destination_prefix":           {"S":     "ucds/weekly-declarations/ni-weekly-decs-allweeks/"},
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
    "destination_prefix":           {"S":     "ucds/weekly-declarations/ni-weekly-decs-4wks/"},
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
    "destination_prefix":           {"S":     "ucds/weekly-declarations/ni-weekly-decs-sites/"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}


resource "aws_dynamodb_table_item" "ers_ad_summary_stats_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/ad_survey/$TODAYS_DATE/ucds/ad_survey/ad_summary_stats/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/ad_survey/ad_summary_stats"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_ad_responses_recent_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/ad_survey/$TODAYS_DATE/ucds/ad_survey/ad_responses_recent/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/ad_survey/ad_responses_recent"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_weekly_agent_online_counts_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/agents_by_role/$TODAYS_DATE/ucds/agents_by_role/weekly_agent_online_counts/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/agents_by_role/weekly_agent_online_counts"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_monthly_agents_online_counts_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/agents_by_role/$TODAYS_DATE/ucds/agents_by_role/monthly_agents_online_counts/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/agents_by_role/monthly_agents_online_counts"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_appointment_status_summary_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/appointments/$TODAYS_DATE/ucds/appointment_status_summary/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/appointment_status_summary"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_appointment_counts_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/appointments/$TODAYS_DATE/ucds/appointment_counts/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/appointment_counts"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_daily_audit_events_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/audit_events/$TODAYS_DATE/ucds/daily_audit_events/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/daily_audit_events"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_contracts_stats_summary_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/claimant_mi/$TODAYS_DATE/ucds/contracts_stats_summary/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/contracts_stats_summary"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_count_euss_all_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/euss/$TODAYS_DATE/ucds/count_euss_all/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/count_euss_all"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_todo_summary_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/knowingme_knowingtodo/$TODAYS_DATE/ucds/knowingme_knowingtodo/todo_summary/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/knowingme_knowingtodo/todo_summary"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_todos_by_day_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/knowingme_knowingtodo/$TODAYS_DATE/ucds/knowingme_knowingtodo/todos_by_day/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/knowingme_knowingtodo/todos_by_day"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_all_time_aggregation_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/ucr_general/$TODAYS_DATE/pdmoutput/ucr/all_time_aggregation/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/ucr/all_time_aggregation"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_daily_aggregation_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/ucr_general/$TODAYS_DATE/pdmoutput/ucr/daily_aggregation/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/ucr/daily_aggregation"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_monthly_aggregation_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/ucr_general/$TODAYS_DATE/pdmoutput/ucr/monthly_aggregation/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/ucr/monthly_aggregation"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_qa_checks_ucr_general_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/ucr_general/$TODAYS_DATE/pdmoutput/ucr/qa_checks/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/ucr/qa_checks"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_summary_sites_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/ukraine/$TODAYS_DATE/ucds/ukraine/summary_sites/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/ukraine/summary_sites"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_aps_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/ukraine/$TODAYS_DATE/ucds/ukraine/aps/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/ukraine/aps"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_qa_checks_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/ukraine/$TODAYS_DATE/ucds/ukraine/qa_checks/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/ukraine/qa_checks"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_homepage_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/journal_dashboard/$TODAYS_DATE/ucds/journal_dashboard/homepage/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/journal_dashboard/homepage"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_associations_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/journal_dashboard/$TODAYS_DATE/ucds/journal_dashboard/associations/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/journal_dashboard/associations"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_group_messages_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/journal_dashboard/$TODAYS_DATE/ucds/journal_dashboard/group_messages/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/journal_dashboard/group_messages"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_inefficiencies_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/journal_dashboard/$TODAYS_DATE/ucds/journal_dashboard/inefficiencies/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/journal_dashboard/inefficiencies"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_claimant_summary_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/uc_ers_reporting/$TODAYS_DATE/ucds/scmc_pilot/claimant_summary/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/scmc_pilot/claimant_summary"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_contract_summary_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/uc_ers_reporting/$TODAYS_DATE/ucds/scmc_pilot/contract_summary/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/scmc_pilot/contract_summary"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_weekly_summary_all_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/uc_ers_reporting/$TODAYS_DATE/ucds/scmc_pilot/weekly_summary/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/scmc_pilot/weekly_summary"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_ecs_suspensions_summary_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/uc_ers_reporting/$TODAYS_DATE/ucds/suspensions_summary/suspensions_summary/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/suspensions_summary/suspensions_summary"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_ecs_suspended_to_unsuspended_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/uc_ers_reporting/$TODAYS_DATE/ucds/suspensions_summary/suspended_to_unsuspended/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/suspensions_summary/suspended_to_unsuspended"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_ecs_suspended_to_closed_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/uc_ers_reporting/$TODAYS_DATE/ucds/suspensions_summary/suspended_to_closed/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/suspensions_summary/suspended_to_closed"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_ecs_weekly_summary_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/uc_ers_reporting/$TODAYS_DATE/ucds/scmc_pilot/ecs_summary/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/scmc_pilot/ecs_summary"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_service_goal_2_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/service_goals/$TODAYS_DATE/ucds/service_goals/service_goal_2/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/service_goals/service_goal_2/headline"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_service_goal_3_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/service_goals/$TODAYS_DATE/ucds/service_goals/service_goal_3/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/service_goals/service_goal_3/headline"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_service_goal_4_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/service_goals/$TODAYS_DATE/ucds/service_goals/service_goal_4/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/service_goals/service_goal_4/headline"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_service_goal_5_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/service_goals/$TODAYS_DATE/ucds/service_goals/service_goal_5/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/service_goals/service_goal_5/headline"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_service_goal_6_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/service_goals/$TODAYS_DATE/ucds/service_goals/service_goal_6/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/service_goals/service_goal_6/headline"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_service_goal_7_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/service_goals/$TODAYS_DATE/ucds/service_goals/service_goal_7/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/service_goals/service_goal_7/headline"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_service_goal_8_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/service_goals/$TODAYS_DATE/ucds/service_goals/service_goal_8/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/service_goals/service_goal_8/headline"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_retro_2_outcome_codes_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/retro_2/$TODAYS_DATE/ucds/retro_2/retro_2_outcome_codes/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/retro_2/outcomes"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_retro_2_ame_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/retro_2/$TODAYS_DATE/ucds/retro_2/retro_2_ame/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/retro_2/ame"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_retro_2_mvfe_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/retro_2/$TODAYS_DATE/ucds/retro_2/retro_2_mvfe/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/retro_2/mvfe"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_backfill_logins_by_time_summary_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/logins_by_time/$TODAYS_DATE/ucds/logins_by_time/backfill_logins_by_time_summary/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/logins_by_time/claimant_backfill"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_update_trial_allocation_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/update_trial_allocation/$TODAYS_DATE/ucds/update_trial_allocation/trial_allocation/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/trial_allocation"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_update_frontier_workers_summary_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/update_frontier_workers/$TODAYS_DATE/ucds/update_frontier_workers/frontier_workers_summary/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/frontiers_workers_dashboard/frontier_workers_summary"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_update_timely_payments_summary_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/update_timely_payments/$TODAYS_DATE/ucds/update_timely_payments/monthly_payments_late/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/late_payments/monthly"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_late_payments_data_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/paid_on_time/$TODAYS_DATE/ucds/late_payments/weekly/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/late_payments/weekly"},
    "decrypt":                      {"bool":   true},
    "rewrap_datakey":               {"bool":   false},
    "encrypting_key_ssm_parm_name": {"S":      ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ers_contract_payment_characteristics_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/ers/contract_payment_characteristics/$TODAYS_DATE/ucds/contract_payment_characteristics/*"},
    "pipeline_name":                {"S":     "ERS"},
    "recipient_name":               {"S":     "ERS"},
    "transfer_type":                {"S":     "S3"},
    "source_bucket":                {"S":     "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":     "${local.oneservice[local.environment].bucket_name}"},
    "destination_prefix":           {"S":     "ucds/contract_payment_characteristics"},
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

  for_each = nonsensitive(toset([for ris_collection in local.ris_collections : ris_collection if ris_collection != "NOT_SET"]))

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

resource "aws_dynamodb_table_item" "sas_extracts_welfare_grant_egress_config" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":     "dataegress/sas/welfare_grant/export/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":     "SAS_WELFARE_GRANT_SFT"},
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

resource "aws_dynamodb_table_item" "ap_ml_preprocessed_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/journal/preprocessed_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_journal"},
    "recipient_name":               {"S":    "ap_preproc_journal"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/journal/preprocessed_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_preprocessed_training_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/journal/preprocessed_training_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_journal"},
    "recipient_name":               {"S":    "ap_preproc_journal_training"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/journal/preprocessed_training_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}
resource "aws_dynamodb_table_item" "ap_ml_model_1_preprocessed_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_1/preprocessed_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_1"},
    "recipient_name":               {"S":    "ap_preproc_model_1"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_1/preprocessed_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_model_1_preprocessed_training_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_1/preprocessed_training_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_1"},
    "recipient_name":               {"S":    "ap_preproc_model_1_training"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_1/preprocessed_training_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_model_2_preprocessed_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_2/preprocessed_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_2"},
    "recipient_name":               {"S":    "ap_preproc_model_2"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_2/preprocessed_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_model_2_preprocessed_training_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_2/preprocessed_training_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_2"},
    "recipient_name":               {"S":    "ap_preproc_model_2_training"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_2/preprocessed_training_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_model_3_preprocessed_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_3/preprocessed_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_3"},
    "recipient_name":               {"S":    "ap_preproc_model_3"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_3/preprocessed_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_model_3_preprocessed_training_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_3/preprocessed_training_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_3"},
    "recipient_name":               {"S":    "ap_preproc_model_3_training"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_3/preprocessed_training_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_model_4_preprocessed_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_4/preprocessed_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_4"},
    "recipient_name":               {"S":    "ap_preproc_model_4"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_4/preprocessed_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_model_4_preprocessed_training_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_4/preprocessed_training_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_4"},
    "recipient_name":               {"S":    "ap_preproc_model_4_training"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_4/preprocessed_training_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_model_5_preprocessed_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_5/preprocessed_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_5"},
    "recipient_name":               {"S":    "ap_preproc_model_5"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_5/preprocessed_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_model_5_preprocessed_training_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_5/preprocessed_training_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_5"},
    "recipient_name":               {"S":    "ap_preproc_model_5_training"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_5/preprocessed_training_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_model_6_preprocessed_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_6/preprocessed_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_6"},
    "recipient_name":               {"S":    "ap_preproc_model_6"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_6/preprocessed_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_model_6_preprocessed_training_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_6/preprocessed_training_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_6"},
    "recipient_name":               {"S":    "ap_preproc_model_6_training"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_6/preprocessed_training_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_model_7_preprocessed_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_7/preprocessed_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_7"},
    "recipient_name":               {"S":    "ap_preproc_model_7"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_7/preprocessed_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_model_7_preprocessed_training_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_7/preprocessed_training_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_7"},
    "recipient_name":               {"S":    "ap_preproc_model_7_training"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_7/preprocessed_training_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}
resource "aws_dynamodb_table_item" "ap_ml_model_8_preprocessed_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_8/preprocessed_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_8"},
    "recipient_name":               {"S":    "ap_preproc_model_8"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_8/preprocessed_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_model_8_preprocessed_training_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_8/preprocessed_training_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_8"},
    "recipient_name":               {"S":    "ap_preproc_model_8_training"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_8/preprocessed_training_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}
resource "aws_dynamodb_table_item" "ap_ml_model_9_preprocessed_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_9/preprocessed_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_9"},
    "recipient_name":               {"S":    "ap_preproc_model_9"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_9/preprocessed_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_model_9_preprocessed_training_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_9/preprocessed_training_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_9"},
    "recipient_name":               {"S":    "ap_preproc_model_9_training"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_9/preprocessed_training_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_model_10_preprocessed_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_10/preprocessed_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_10"},
    "recipient_name":               {"S":    "ap_preproc_model_10"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_10/preprocessed_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
    "rewrap_datakey":               {"bool": false},
    "encrypting_key_ssm_parm_name": {"S":    ""}
  }
  ITEM
}

resource "aws_dynamodb_table_item" "ap_ml_model_10_preprocessed_training_data" {
  table_name = aws_dynamodb_table.data_egress.name
  hash_key   = aws_dynamodb_table.data_egress.hash_key
  range_key  = aws_dynamodb_table.data_egress.range_key

  item = <<ITEM
  {
    "source_prefix":                {"S":    "ap_ml/model_10/preprocessed_training_data/$TODAYS_DATE/*"},
    "pipeline_name":                {"S":    "ap_preproc_model_10"},
    "recipient_name":               {"S":    "ap_preproc_model_10_training"},
    "transfer_type":                {"S":    "S3"},
    "source_bucket":                {"S":    "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
    "destination_bucket":           {"S":    "${data.terraform_remote_state.common.outputs.dataworks_model_published_bucket.id}"},
    "destination_prefix":           {"S":    "ap_ml/model_10/preprocessed_training_data/$TODAYS_DATE/"},
    "decrypt":                      {"bool": true},
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

resource "aws_s3_object" "data_egress_server_logrotate_script" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/data-egress-server/data-egress-server.logrotate"
  content    = data.local_file.data_egress_server_logrotate_script.content
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn



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

resource "aws_s3_object" "data_egress_server_cloudwatch_script" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/data-egress-server/data-egress-server-cloudwatch.sh"
  content    = data.local_file.data_egress_server_cloudwatch_script.content
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn

  tags = merge(
    local.common_tags,
    {
      Name = "data-egress-server-cloudwatch-script"
    },
  )
}

data "local_file" "data_egress_server_logging_script" {
  filename = "files/logging.sh"
}

resource "aws_s3_object" "data_egress_server_logging_script" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/data-egress-server/data-egress-server-logging.sh"
  content    = data.local_file.data_egress_server_logging_script.content
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn

  tags = merge(
    local.common_tags,
    {
      Name = "data-egress-server-logging-script"
    },
  )
}

data "local_file" "data_egress_server_config_hcs_script" {
  filename = "files/config_hcs.sh"
}

resource "aws_s3_object" "data_egress_server_config_hcs_script" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/data-egress-server/data-egress-server-config-hcs.sh"
  content    = data.local_file.data_egress_server_config_hcs_script.content
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn

  tags = merge(
    local.common_tags,
    {
      Name = "data-egress-server-config-hcs-script"
    },
  )
}
