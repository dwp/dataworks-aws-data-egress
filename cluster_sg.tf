resource "aws_security_group" "data_egress_server" {
  name        = "data_egress_server"
  description = "Control access to and from data egress server"
  vpc_id      = data.terraform_remote_state.aws_sdx.outputs.vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = local.data_egress_server_name
    }
  )
}

locals {
  server_security_group_rules = [
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
}

resource "aws_security_group_rule" "server_ingress" {
  for_each                 = { for security_group_rule in local.server_security_group_rules : security_group_rule.name => security_group_rule }
  description              = "Allow inbound requests from ${each.value.name}"
  type                     = "ingress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = "tcp"
  security_group_id        = each.value.destination
  source_security_group_id = aws_security_group.data_egress_server.id
}

resource "aws_security_group_rule" "server_egress" {
  for_each                 = { for security_group_rule in local.server_security_group_rules : security_group_rule.name => security_group_rule }
  description              = "Allow outbound requests to ${each.value.name}"
  type                     = "egress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = "tcp"
  source_security_group_id = each.value.destination
  security_group_id        = aws_security_group.data_egress_server.id
}

//The below rules are to pull docker image from ecr
resource "aws_security_group_rule" "data_egress_server_s3_https" {
  description       = "Access to S3 https"
  type              = "egress"
  prefix_list_ids   = [data.terraform_remote_state.aws_sdx.outputs.vpc.prefix_list_ids.s3]
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.data_egress_server.id
}

resource "aws_security_group_rule" "data_egress_server_s3_http" {
  description       = "Access to S3 http"
  type              = "egress"
  prefix_list_ids   = [data.terraform_remote_state.aws_sdx.outputs.vpc.prefix_list_ids.s3]
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  security_group_id = aws_security_group.data_egress_server.id
}
