# resource "aws_ecs_task_definition" "sft-agent" {
#   family                   = "sft-agent"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["EC2"]
#   cpu                      = "4096"
#   memory                   = "8192"
#   task_role_arn            = aws_iam_role.sft_agent_task.arn
#   execution_role_arn       = data.terraform_remote_state.common.outputs.ecs_task_execution_role.arn
#   container_definitions    = "[${data.template_file.sft_agent_definition.rendered}]"
#   tags                     = merge(local.tags, { Name = var.name })
# }


# resource "aws_ecs_service" "sft-agent" {
#   name            = "sft-agent"
#   cluster         = aws_ecs_cluster.data_egress_cluster.id
#   task_definition = aws_ecs_task_definition.sft-agent.arn
#   desired_count   = local.sft_agent_service_desired_count[local.environment]
#   launch_type     = "EC2"


#   network_configuration {
#     security_groups = [aws_security_group.sft_agent_service.id]
#     subnets         = data.terraform_remote_state.aws_sdx.outputs.subnet_sdx_connectivity.*.id
#   }

#   service_registries {
#     registry_arn   = aws_service_discovery_service.data-egress.arn
#     container_name = "sft-agent"
#   }

#   tags = merge(local.tags, { Name = var.name })
# }
