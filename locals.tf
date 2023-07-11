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
    preprod     = "True"
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

  management_infra_account = {
    development    = "default"
    qa             = "default"
    integration    = "default"
    management-dev = "default"
    preprod        = "management"
    production     = "management"
    management     = "management"
  }

  dataworks_root_domain = "dataworks.dwp.gov.uk"

  dataworks_domain_env_prefix = {
    development = "dev."
    qa          = "qa."
    integration = "int."
    preprod     = "pre."
    production  = ""
  }

  stub_nifi_friendly_name = "stub-nifi"
  stub_nifi_alb_fqdn      = "${local.stub_nifi_friendly_name}.${local.dataworks_domain_env_prefix[local.environment]}${local.dataworks_root_domain}"

  use_stub_nifi = {
    development = true
    qa          = true
    integration = true
    preprod     = false
    production  = false
  }

  use_data_ingress = {
    development = true
    qa          = true
    integration = true
    preprod     = false
    production  = false
  }

  config_bucket_arn = data.terraform_remote_state.common.outputs.config_bucket["arn"]
  config_bucket_cmk = data.terraform_remote_state.common.outputs.config_bucket_cmk["arn"]


  config_file = "agent-application-config.tpl"

  agent_config_file = {
    development = "agent-config.tpl"
    qa          = "agent-config.tpl"
    integration = "agent-config.tpl"
    preprod     = "agent-config-with-tls.tpl"
    production  = "agent-config-with-tls.tpl"
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
    development = "1"
    qa          = "1"
    integration = "1"
    preprod     = "1"
    production  = "1"
  }

  sft_agent_group_name       = "sft_agent"
  sft_agent_config_s3_prefix = "component/data-egress-sft"

  data-egress_group_name       = "data-egress"
  data-egress_config_s3_prefix = "monitoring/${local.data-egress_group_name}"

  truststore_aliases = {
    development = "dataworks_root_ca,dataworks_mgt_root_ca"
    qa          = "dataworks_root_ca,dataworks_mgt_root_ca"
    integration = "dataworks_root_ca,dataworks_mgt_root_ca"
    preprod     = "dataworks_root_ca,dataworks_mgt_root_ca,sdx1,sdx2,sft_hub_root_ca"
    production  = "dataworks_root_ca,dataworks_mgt_root_ca,sdx1,sdx2,sft_hub_root_ca"
  }

  truststore_certs = {
    development = "s3://${local.env_certificate_bucket}/ca_certificates/dataworks/dataworks_root_ca.pem,s3://${data.terraform_remote_state.mgmt_ca.outputs.public_cert_bucket.id}/ca_certificates/dataworks/dataworks_root_ca.pem"
    qa          = "s3://${local.env_certificate_bucket}/ca_certificates/dataworks/dataworks_root_ca.pem,s3://${data.terraform_remote_state.mgmt_ca.outputs.public_cert_bucket.id}/ca_certificates/dataworks/dataworks_root_ca.pem"
    integration = "s3://${local.env_certificate_bucket}/ca_certificates/dataworks/dataworks_root_ca.pem,s3://${data.terraform_remote_state.mgmt_ca.outputs.public_cert_bucket.id}/ca_certificates/dataworks/dataworks_root_ca.pem"
    preprod     = "s3://${local.env_certificate_bucket}/ca_certificates/dataworks/dataworks_root_ca.pem,s3://${data.terraform_remote_state.mgmt_ca.outputs.public_cert_bucket.id}/ca_certificates/dataworks/dataworks_root_ca.pem,s3://${data.terraform_remote_state.certificate_authority.outputs.public_cert_bucket.id}/server_certificates/sdx/service_1/sdx_mitm.pem,s3://${data.terraform_remote_state.certificate_authority.outputs.public_cert_bucket.id}/server_certificates/sdx/service_2/sdx_mitm.pem,s3://${data.terraform_remote_state.certificate_authority.outputs.public_cert_bucket.id}/server_certificates/aws_sft_hub/sft_hub_root.crt"
    production  = "s3://${local.env_certificate_bucket}/ca_certificates/dataworks/dataworks_root_ca.pem,s3://${data.terraform_remote_state.mgmt_ca.outputs.public_cert_bucket.id}/ca_certificates/dataworks/dataworks_root_ca.pem,s3://${data.terraform_remote_state.certificate_authority.outputs.public_cert_bucket.id}/server_certificates/sdx/service_1/sdx_mitm.pem,s3://${data.terraform_remote_state.certificate_authority.outputs.public_cert_bucket.id}/server_certificates/sdx/service_2/sdx_mitm.pem,s3://${data.terraform_remote_state.certificate_authority.outputs.public_cert_bucket.id}/server_certificates/aws_sft_hub/sft_hub_root.crt"
  }

  keystore_aliases = {
    development = "aws_sft_hub_signed"
    qa          = "aws_sft_hub_signed"
    integration = "aws_sft_hub_signed"
    preprod     = "aws_sft_hub_signed"
    production  = "aws_sft_hub_signed"
  }

  keystore_certs = {
    development = "s3://${data.terraform_remote_state.certificate_authority.outputs.public_cert_bucket.id}/server_certificates/aws_sft_hub/aws_sft_hub_signed.crt"
    qa          = "s3://${data.terraform_remote_state.certificate_authority.outputs.public_cert_bucket.id}/server_certificates/aws_sft_hub/aws_sft_hub_signed.crt"
    integration = "s3://${data.terraform_remote_state.certificate_authority.outputs.public_cert_bucket.id}/server_certificates/aws_sft_hub/aws_sft_hub_signed.crt"
    preprod     = "s3://${data.terraform_remote_state.certificate_authority.outputs.public_cert_bucket.id}/server_certificates/aws_sft_hub/aws_sft_hub_signed.crt"
    production  = "s3://${data.terraform_remote_state.certificate_authority.outputs.public_cert_bucket.id}/server_certificates/aws_sft_hub/aws_sft_hub_signed.crt"
  }

  test_sft = {
    development    = "TRUE"
    qa             = "TRUE"
    integration    = ""
    management-dev = ""
    preprod        = ""
    production     = ""
    management     = ""
  }

  sft_test_dir = {
    development    = "test"
    qa             = "test"
    integration    = ""
    management-dev = ""
    preprod        = ""
    production     = ""
    management     = ""
  }

  ssl_debug = {
    development    = "all"
    qa             = "ssl"
    integration    = "ssl"
    management-dev = "ssl"
    preprod        = "ssl"
    production     = "ssl"
    management     = "ssl"
  }

  configure_ssl = {
    development    = ""
    qa             = ""
    integration    = ""
    management-dev = ""
    preprod        = "true"
    production     = "true"
    management     = ""
  }


  secret_name_for_pdm_queries                 = "/concourse/dataworks/rtg/pdm"
  secret_name_for_rtg_full_collections        = "/concourse/dataworks/rtg/full"
  secret_name_for_rtg_incremental_collections = "/concourse/dataworks/rtg/incremental"
  secret_name_for_ris_collections             = "/htme/collections/ris"

  rtg_pdm_queries             = csvdecode(data.aws_secretsmanager_secret_version.rtg_secret_pdm_queries.secret_binary)
  rtg_full_collections        = csvdecode(data.aws_secretsmanager_secret_version.rtg_secret_full_collections.secret_binary)
  rtg_incremental_collections = csvdecode(data.aws_secretsmanager_secret_version.rtg_secret_incremental_collections.secret_binary)
  ris_collections             = split("\n", chomp(base64decode(data.aws_secretsmanager_secret_version.secret_for_ris_collections.secret_string)))

  tenable_install = {
    development    = "true"
    qa             = "true"
    integration    = "true"
    preprod        = "true"
    production     = "true"
    management-dev = "true"
    management     = "true"
  }

  trend_install = {
    development    = "true"
    qa             = "true"
    integration    = "true"
    preprod        = "true"
    production     = "true"
    management-dev = "true"
    management     = "true"
  }

  tanium_install = {
    development    = "true"
    qa             = "true"
    integration    = "true"
    preprod        = "true"
    production     = "true"
    management-dev = "true"
    management     = "true"
  }


  ## Tanium config
  ## Tanium Servers
  tanium1 = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).tanium[local.environment].server_1
  tanium2 = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).tanium[local.environment].server_2

  ## Tanium Env Config
  tanium_env = {
    development    = "pre-prod"
    qa             = "prod"
    integration    = "prod"
    preprod        = "prod"
    production     = "prod"
    management-dev = "pre-prod"
    management     = "prod"
  }

  ## Tanium prefix list for TGW for Security Group rules
  tanium_prefix = {
    development    = [data.aws_ec2_managed_prefix_list.list.id]
    qa             = [data.aws_ec2_managed_prefix_list.list.id]
    integration    = [data.aws_ec2_managed_prefix_list.list.id]
    preprod        = [data.aws_ec2_managed_prefix_list.list.id]
    production     = [data.aws_ec2_managed_prefix_list.list.id]
    management-dev = [data.aws_ec2_managed_prefix_list.list.id]
    management     = [data.aws_ec2_managed_prefix_list.list.id]
  }

  tanium_log_level = {
    development    = "41"
    qa             = "41"
    integration    = "41"
    preprod        = "41"
    production     = "41"
    management-dev = "41"
    management     = "41"
  }

  ## Trend config
  tenant   = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).trend.tenant
  tenantid = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).trend.tenantid
  token    = jsondecode(data.aws_secretsmanager_secret_version.terraform_secrets.secret_binary).trend.token

  policy_id = {
    development    = "1671"
    qa             = "1671"
    integration    = "1671"
    preprod        = "1717"
    production     = "1717"
    management-dev = "1671"
    management     = "1717"
  }

}
