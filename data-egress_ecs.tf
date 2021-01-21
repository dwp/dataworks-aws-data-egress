resource "aws_ecs_task_definition" "data-egress" {
  family                   = "data-egress"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "2048"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.data_egress_server_task.arn
  execution_role_arn       = data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
  container_definitions    = "[${data.template_file.data_egress_definition.rendered}]"

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
    group_name         = "data-egress"
    cpu                = var.fargate_cpu
    image_url          = format("%s:%s", data.terraform_remote_state.management.outputs.dataworks_data_egress_url, "latest")
    memory             = var.receiver_memory
    memory_reservation = var.fargate_memory
    user               = "nobody"
    ports              = jsonencode([var.data_egress_port])
    ulimits            = jsonencode([])
    log_group          = aws_cloudwatch_log_group.data_egress_cluster.name
    region             = data.aws_region.current.name
    config_bucket      = data.terraform_remote_state.common.outputs.config_bucket.id

    mount_points = jsonencode([
      {
        "container_path" : "/data-egress",
        "source_volume" : "data-egress"
      }
    ])

    environment_variables = jsonencode([
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
    security_groups = [aws_security_group.data_egress_service.id]
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

