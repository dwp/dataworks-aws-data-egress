locals {

  is_mgmt_env = {
    development    = false
    qa             = false
    integration    = false
    preprod        = false
    production     = false
    management     = true
    management-dev = true
  }

  env_prefix = {
    development    = "dev."
    qa             = "qa."
    stage          = "stg."
    integration    = "int."
    preprod        = "pre."
    production     = ""
    management-dev = "mgt-dev."
    management     = "mgt."
  }

  data_egress_server_asg_min = {
    development    = 1
    qa             = 1
    integration    = 1
    preprod        = 1
    production     = 1
    management-dev = 0
    management     = 0
  }
  data_egress_server_asg_desired = {
    development    = 1
    qa             = 1
    integration    = 1
    preprod        = 1
    production     = 1
    management-dev = 0
    management     = 0
  }
  data_egress_server_asg_max = {
    development    = 1
    qa             = 1
    integration    = 1
    preprod        = 1
    production     = 1
    management-dev = 0
    management     = 0
  }
  data_egress_server_ssmenabled = {
    development    = "True"
    qa             = "True"
    integration    = "True"
    preprod        = "False"
    production     = "False"
    management-dev = "False"
    management     = "False"
  }

  crypto_workspace = {
    management-dev = "management-dev"
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
}
