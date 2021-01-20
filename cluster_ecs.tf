resource "aws_ecs_cluster" "data_egress_cluster" {
  name               = local.cluster_name
  capacity_providers = [aws_ecs_capacity_provider.data_egress_cluster.name]

  tags = merge(
    local.tags,
    {
      Name = local.data_egress_ecs_friendly_name
    }
  )

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "data_egress_cluster" {
  name              = local.cw_agent_log_group_name_data_egress_ecs
  retention_in_days = 180
  tags              = local.tags
}

resource "aws_ecs_capacity_provider" "data_egress_cluster" {
  name = local.data_egress_friendly_name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.data_egress_server.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 10
    }
  }

  lifecycle {
    ignore_changes = all
  }

  tags = merge(
    local.tags,
    {
      Name = local.data_egress_friendly_name
    }
  )
}


