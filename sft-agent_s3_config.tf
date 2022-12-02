resource "aws_s3_bucket_object" "data_egress_sft_agent_config" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.sft_agent_config_s3_prefix}/agent-config.yml"
  content    = data.template_file.data_egress_sft_agent_config_tpl.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "data_egress_sft_agent_application_config" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "${local.sft_agent_config_s3_prefix}/agent-application-config.yml"
  content    = data.template_file.data_egress_sft_agent_application_config_tpl.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

data "template_file" "data_egress_sft_agent_config_tpl" {
  template = file("${path.module}/sft_config/${local.agent_config_file[local.environment]}")
  vars = {
    apiKey = local.sft_hub_api_key
  }
}

data "template_file" "data_egress_sft_agent_application_config_tpl" {
  template = file("${path.module}/sft_config/${local.config_file}")
  vars = {
    destination_url = local.use_stub_nifi[local.environment] ? local.stub_nifi_alb_fqdn : data.terraform_remote_state.aws_sdx.outputs.sdx_f5_endpoint_1_name[0]
  }
}
