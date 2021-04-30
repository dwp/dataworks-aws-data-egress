resource "aws_ecs_task_definition" "sft-agent" {
  family                   = "sft-agent"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "4096"
  memory                   = "8192"
  task_role_arn            = aws_iam_role.sft_agent_task.arn
  execution_role_arn       = data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.sft_agent_definition.rendered}]"
  tags                     = merge(local.tags, { Name = var.name })
}

data "template_file" "sft_agent_definition" {
  template = file("${path.module}/reserved_container_definition.tpl")
  vars = {
    name               = "sft-agent"
    group_name         = local.sft_agent_group_name
    cpu                = var.fargate_cpu
    image_url          = format("%s:%s", data.terraform_remote_state.management.outputs.ecr_sft_agent_url, var.sft_agent_image_version)
    memory             = var.receiver_memory
    memory_reservation = var.fargate_memory
    user               = "root"
    ports              = jsonencode([parseint(var.sft_agent_port, 10)])
    ulimits            = jsonencode([])
    log_group          = aws_cloudwatch_log_group.data_egress_cluster.name
    region             = data.aws_region.current.name
    config_bucket      = data.terraform_remote_state.common.outputs.config_bucket.id
    s3_prefix          = local.sft_agent_config_s3_prefix

    mount_points = jsonencode([
      //      {
      //        "container_path" : "/sft-agent",
      //        "source_volume" : "sft-agent"
      //      }
    ])

    environment_variables = jsonencode([
      {
        name  = "internet_proxy",
        value = data.terraform_remote_state.aws_sdx.outputs.internet_proxy.host
      },
      {
        name  = "non_proxied_endpoints",
        value = join(",", data.terraform_remote_state.aws_sdx.outputs.vpc.no_proxy_list)
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
        name : "LOG_LEVEL",
        value : "DEBUG"
      }

    ])
  }
}

resource "aws_ecs_service" "sft-agent" {
  name            = "sft-agent"
  cluster         = aws_ecs_cluster.data_egress_cluster.id
  task_definition = aws_ecs_task_definition.sft-agent.arn
  desired_count   = 1
  launch_type     = "EC2"


  network_configuration {
    security_groups = [aws_security_group.sft_agent_service.id]
    subnets         = data.terraform_remote_state.aws_sdx.outputs.subnet_sdx_connectivity.*.id
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.data-egress.arn
    container_name = "sft-agent"
  }

  tags = merge(local.tags, { Name = var.name })
}
