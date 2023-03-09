resource "aws_ecs_task_definition" "data-egress" {
  family                   = "data-egress"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.task_definition_cpu[local.environment]
  memory                   = var.task_definition_memory[local.environment]
  task_role_arn            = aws_iam_role.data_egress_server_task.arn
  execution_role_arn       = data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.data_egress_definition.rendered}, ${data.template_file.sft_agent_definition.rendered}]"

  volume {
    name = "data-egress"
    docker_volume_configuration {
      scope         = "shared"
      autoprovision = true
      driver        = "local"
    }
  }
  tags = merge(local.tags, { Name = var.name })
}

data "template_file" "data_egress_definition" {
  template = file("${path.module}/reserved_container_definition.tpl")
  vars = {
    name               = "data-egress"
    group_name         = local.data-egress_group_name
    cpu                = var.fargate_cpu[local.environment]
    image_url          = format("%s:%s", data.terraform_remote_state.management.outputs.dataworks_data_egress_url, var.data_egress_image_version[local.environment])
    memory             = var.data_egress_receiver_memory[local.environment]
    memory_reservation = var.fargate_memory
    user               = "root"
    ports              = jsonencode([var.data_egress_port])
    ulimits            = jsonencode([])
    log_group          = aws_cloudwatch_log_group.data_egress_cluster.name
    region             = data.aws_region.current.name
    config_bucket      = data.terraform_remote_state.common.outputs.config_bucket.id
    s3_prefix          = local.data-egress_config_s3_prefix
    essential          = true

    mount_points = jsonencode([
      {
        "container_path" : "/data-egress",
        "source_volume" : "data-egress"
      }
    ])

    environment_variables = jsonencode([
      {
        name  = "sqs_url",
        value = data.terraform_remote_state.common.outputs.data_egress_sqs.id
      },
      {
        name  = "dks_url",
        value = data.terraform_remote_state.crypto.outputs.dks_endpoint[local.environment]
      },
      {
        name  = "acm_cert_arn",
        value = aws_acm_certificate.data_egress_server.arn
      },
      {
        name  = "truststore_aliases",
        value = local.truststore_aliases[local.environment]
      },
      {
        name  = "truststore_certs",
        value = local.truststore_certs[local.environment]
      },
      {
        name  = "keystore_aliases",
        value = local.keystore_aliases[local.environment]
      },
      {
        name  = "keystore_certs",
        value = local.keystore_certs[local.environment]
      },
      {
        name  = "private_key_alias",
        value = "data_egress"
      },
      {
        name  = "internet_proxy",
        value = data.terraform_remote_state.aws_sdx.outputs.internet_proxy.host
      },
      {
        name  = "non_proxied_endpoints",
        value = join(",", data.terraform_remote_state.aws_sdx.outputs.vpc.no_proxy_list)
      },
      {
        name  = "dks_fqdn",
        value = local.dks_fqdn
      },
      {
        name  = "AWS_REGION",
        value = var.region
      },
      {
        name : "AWS_DEFAULT_REGION",
        value : var.region
      },
      {
        name : "METRICS_PUSHGATEWAY_HOST",
        value : "${data.terraform_remote_state.aws_sdx.outputs.private_dns.sdx_service_discovery.name}.${data.terraform_remote_state.aws_sdx.outputs.private_dns.sdx_service_discovery_dns.name}"
      }

    ])
  }
}

data "template_file" "sft_agent_definition" {
  template = file("${path.module}/reserved_container_definition.tpl")
  vars = {
    name               = "sft-agent"
    group_name         = local.sft_agent_group_name
    cpu                = var.fargate_cpu[local.environment]
    image_url          = format("%s:%s", data.terraform_remote_state.management.outputs.ecr_sft_agent_url, var.sft_agent_image_version[local.environment])
    memory             = var.sft_receiver_memory[local.environment]
    memory_reservation = var.fargate_memory
    user               = "root"
    ports              = jsonencode([9996])
    ulimits            = jsonencode([])
    log_group          = aws_cloudwatch_log_group.data_egress_cluster.name
    region             = data.aws_region.current.name
    config_bucket      = data.terraform_remote_state.common.outputs.config_bucket.id
    s3_prefix          = local.sft_agent_config_s3_prefix
    essential          = true

    mount_points = jsonencode([
      {
        "container_path" : "/data-egress",
        "source_volume" : "data-egress"
      }
    ])

    environment_variables = jsonencode([
      {
        name  = "AWS_REGION",
        value = var.region
      },
      {
        name : "AWS_DEFAULT_REGION",
        value : var.region
      },
      {
        name : "LOG_LEVEL",
        value : "DEBUG"
      },
      {
        name  = "acm_cert_arn",
        value = aws_acm_certificate.data_egress_server.arn
      },
      {
        name  = "truststore_aliases",
        value = local.truststore_aliases[local.environment]
      },
      {
        name  = "truststore_certs",
        value = local.truststore_certs[local.environment]
      },
      {
        name  = "keystore_aliases",
        value = local.keystore_aliases[local.environment]
      },
      {
        name  = "keystore_certs",
        value = local.keystore_certs[local.environment]
      },
      {
        name  = "private_key_alias",
        value = "data_egress"
      },
      {
        name  = "internet_proxy",
        value = data.terraform_remote_state.aws_sdx.outputs.internet_proxy.host
      },
      {
        name  = "non_proxied_endpoints",
        value = join(",", data.terraform_remote_state.aws_sdx.outputs.vpc.no_proxy_list)
      },
      {
        name  = "dks_fqdn",
        value = local.dks_fqdn
      },
      {
        name  = "CREATE_TEST_FILES",
        value = local.test_sft[local.environment]
      },
      {
        name  = "TEST_DIRECTORY",
        value = local.sft_test_dir[local.environment]
      },
      {
        name  = "CONFIGURE_SSL",
        value = local.configure_ssl[local.environment]
      },
      {
        name  = "PROMETHEUS",
        value = "true"
      }

    ])
  }
}

resource "aws_ecs_service" "data-egress" {
  name            = "data-egress"
  cluster         = aws_ecs_cluster.data_egress_cluster.id
  task_definition = aws_ecs_task_definition.data-egress.arn
  desired_count   = 1
  launch_type     = "EC2"


  network_configuration {
    security_groups = [aws_security_group.data_egress_service.id, aws_security_group.sft_agent_service.id]
    subnets         = data.terraform_remote_state.aws_sdx.outputs.subnet_sdx_connectivity.*.id
  }
  #TODO load balancer needed?

  service_registries {
    registry_arn   = aws_service_discovery_service.data-egress.arn
    container_name = "data-egress"
  }

  tags = merge(local.tags, { Name = var.name })
}

resource "aws_service_discovery_service" "data-egress" {
  name = "data-egress"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.data-egress.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  tags = merge(local.tags, { Name = var.name })
}

resource "aws_service_discovery_private_dns_namespace" "data-egress" {
  name = "${local.environment}.services.${var.parent_domain_name}"
  vpc  = data.terraform_remote_state.aws_sdx.outputs.vpc.vpc.id
  tags = merge(local.tags, { Name = var.name })
}
