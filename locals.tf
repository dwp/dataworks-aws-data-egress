locals {

  env_prefix = {
    development = "dev."
    qa          = "qa."
    stage       = "stg."
    integration = "int."
    preprod     = "pre."
    production  = ""
  }

  data_egress_server_asg_min = {
    development = 0
    qa          = 0
    integration = 0
    preprod     = 0
    production  = 0
  }

  data_egress_server_asg_desired = {
    development = 2
    qa          = 2
    integration = 2
    preprod     = 2
    production  = 2
  }

  data_egress_server_asg_max = {
    development = 2
    qa          = 2
    integration = 2
    preprod     = 2
    production  = 2
  }

  data_egress_server_ssmenabled = {
    development = "True"
    qa          = "True"
    integration = "True"
    preprod     = "False"
    production  = "False"
  }

  crypto_workspace = {
    management-dev = "management-dev"
    management     = "management"
  }

  management_account = {
    development    = "management-dev"
    qa             = "management-dev"
    integration    = "management-dev"
    management-dev = "management-dev"
    preprod        = "management"
    production     = "management"
    management     = "management"
  }

  data_egress_server_name = "data-egress-server"
  data_egress_server_tags_asg = merge(
    local.common_tags,
    {
      Name        = local.data_egress_server_name,
      Persistence = "Ignore",
    }
  )
  env_certificate_bucket                                = "dw-${local.environment}-public-certificates"
  cw_data_egress_server_agent_namespace                 = "/app/${local.data_egress_server_name}"
  cw_agent_metrics_collection_interval                  = 60
  cw_agent_cpu_metrics_collection_interval              = 60
  cw_agent_disk_measurement_metrics_collection_interval = 60
  cw_agent_disk_io_metrics_collection_interval          = 60
  cw_agent_mem_metrics_collection_interval              = 60
  cw_agent_netstat_metrics_collection_interval          = 60
  dks_endpoint                                          = data.terraform_remote_state.crypto.outputs.dks_endpoint[local.environment]
  dks_fqdn                                              = data.terraform_remote_state.crypto.outputs.dks_fqdn[local.environment]

  service_security_group_rules = [
    {
      name : "VPC endpoints"
      port : 443
      destination : data.terraform_remote_state.aws_sdx.outputs.vpc.interface_vpce_sg_id
    },
    {
      name : "Internet proxy endpoints"
      port : 3128
      destination : data.terraform_remote_state.aws_sdx.outputs.internet_proxy.sg
    },
  ]

  sft_agent_service_desired_count = {
    development    = "1"
    qa             = "1"
    integration    = "1"
    preprod        = "1"
    production     = "1"
  }

  sft_agent_group_name       = "sft_agent"
  sft_agent_config_s3_prefix = "component/data-egress-sft"

  data-egress_group_name       = "data-egress"
  data-egress_config_s3_prefix = "monitoring/${local.data-egress_group_name}"
}
