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

resource "aws_autoscaling_group" "data_egress_server" {
  name                      = local.data_egress_friendly_name
  min_size                  = local.data_egress_server_asg_min[local.environment]
  desired_capacity          = local.data_egress_server_asg_desired[local.environment]
  max_size                  = local.data_egress_server_asg_max[local.environment]
  protect_from_scale_in     = false
  health_check_grace_period = 600
  health_check_type         = "EC2"
  force_delete              = true
  vpc_zone_identifier       = data.terraform_remote_state.aws_sdx.outputs.subnet_sdx_connectivity.*.id

  launch_template {
    id      = aws_launch_template.data_egress_server.id
    version = aws_launch_template.data_egress_server.latest_version
  }

  dynamic "tag" {
    for_each = local.data_egress_server_tags_asg

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "data_egress_server" {
  name          = local.data_egress_friendly_name
  image_id      = var.ecs_hardened_ami_id
  instance_type = var.data_egress_server_ec2_instance_type[local.environment]
  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true

    security_groups = [aws_security_group.data_egress_server.id]
  }
  user_data = base64encode(templatefile("files/data_egress_server_userdata.tpl", {
    environment_name                                 = local.environment
    acm_cert_arn                                     = aws_acm_certificate.data_egress_server.arn
    truststore_aliases                               = join(",", var.truststore_aliases)
    truststore_certs                                 = "s3://${local.env_certificate_bucket}/ca_certificates/dataworks/dataworks_root_ca.pem,s3://${data.terraform_remote_state.mgmt_ca.outputs.public_cert_bucket.id}/ca_certificates/dataworks/dataworks_root_ca.pem"
    private_key_alias                                = "data-egress"
    internet_proxy                                   = data.terraform_remote_state.aws_sdx.outputs.internet_proxy.host
    non_proxied_endpoints                            = join(",", data.terraform_remote_state.aws_sdx.outputs.vpc.no_proxy_list)
    dks_fqdn                                         = local.dks_fqdn
    cwa_namespace                                    = local.cw_data_egress_server_agent_namespace
    cwa_metrics_collection_interval                  = local.cw_agent_metrics_collection_interval
    cwa_cpu_metrics_collection_interval              = local.cw_agent_cpu_metrics_collection_interval
    cwa_disk_measurement_metrics_collection_interval = local.cw_agent_disk_measurement_metrics_collection_interval
    cwa_disk_io_metrics_collection_interval          = local.cw_agent_disk_io_metrics_collection_interval
    cwa_mem_metrics_collection_interval              = local.cw_agent_mem_metrics_collection_interval
    cwa_netstat_metrics_collection_interval          = local.cw_agent_netstat_metrics_collection_interval
    cwa_log_group_name                               = aws_cloudwatch_log_group.data_egress_server_logs.name
    s3_scripts_bucket                                = data.terraform_remote_state.common.outputs.config_bucket.id
    s3_file_data_egress_server_logrotate             = aws_s3_bucket_object.data_egress_server_logrotate_script.id
    s3_file_data_egress_server_logrotate_md5         = md5(data.local_file.data_egress_server_logrotate_script.content)
    s3_file_data_egress_server_cloudwatch_sh         = aws_s3_bucket_object.data_egress_server_cloudwatch_script.id
    s3_file_data_egress_server_cloudwatch_sh_md5     = md5(data.local_file.data_egress_server_cloudwatch_script.content)
  }))
  instance_initiated_shutdown_behavior = "terminate"

  iam_instance_profile {
    arn = aws_iam_instance_profile.data_egress_server.arn
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.data_egress_server_ebs_volume_size[local.environment]
      volume_type           = var.data_egress_server_ebs_volume_type[local.environment]
      delete_on_termination = true
      encrypted             = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.data_egress_friendly_name
    }
  )

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.common_tags,
      {
        Name         = "data_egress_server"
        Application  = "data_egress_server"
        Persistence  = "Ignore"
        AutoShutdown = "False"
        SSMEnabled   = local.data_egress_server_ssmenabled[local.environment]
      }
    )
  }
}
