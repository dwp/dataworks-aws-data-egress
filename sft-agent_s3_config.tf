resource "aws_s3_bucket_object" "data_egress_sft_agent_config" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/data-egress-sft/agent-config.yml"
  content    = data.template_file.data_egress_sft_agent_config_tpl.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

resource "aws_s3_bucket_object" "data_egress_sft_agent_application_config" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/data-egress-sft/agent-application-config.yml"
  content    = data.template_file.data_egress_sft_agent_application_config_tpl.rendered
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn
}

data "template_file" "data_egress_sft_agent_config_tpl" {
  template = file("${path.module}/agent-config.tpl")
  vars = {
    apiKey = local.data_egress[local.environment].sft_agent_api_key
  }
}

data "template_file" "data_egress_sft_agent_application_config_tpl" {
  template = file("${path.module}/agent-application-config.tpl")
  vars = {
    destinationIP = local.data_egress[local.environment].sft_agent_destination_ip
  }
}
