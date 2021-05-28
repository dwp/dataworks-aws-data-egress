resource "aws_security_group" "data_egress_service" {
  name        = "data_egress_service"
  description = "Control access to and from data egress service"
  vpc_id      = data.terraform_remote_state.aws_sdx.outputs.vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = "data_egress_service"
    }
  )
}

resource "aws_security_group_rule" "service_ingress" {
  for_each                 = { for security_group_rule in local.service_security_group_rules : security_group_rule.name => security_group_rule }
  description              = "Allow inbound requests from ${each.value.name}"
  type                     = "ingress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = "tcp"
  security_group_id        = each.value.destination
  source_security_group_id = aws_security_group.data_egress_service.id
}

resource "aws_security_group_rule" "service_egress" {
  for_each                 = { for security_group_rule in local.service_security_group_rules : security_group_rule.name => security_group_rule }
  description              = "Allow outbound requests to ${each.value.name}"
  type                     = "egress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = "tcp"
  source_security_group_id = each.value.destination
  security_group_id        = aws_security_group.data_egress_service.id
}

resource "aws_security_group_rule" "data_egress_service_s3_https" {
  description       = "Access to S3 https"
  type              = "egress"
  prefix_list_ids   = [data.terraform_remote_state.aws_sdx.outputs.vpc.prefix_list_ids.s3]
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.data_egress_service.id
}

resource "aws_security_group_rule" "data_egress_service_s3_http" {
  description       = "Access to S3 http"
  type              = "egress"
  prefix_list_ids   = [data.terraform_remote_state.aws_sdx.outputs.vpc.prefix_list_ids.s3]
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  security_group_id = aws_security_group.data_egress_service.id
}

resource "aws_security_group_rule" "data_egress_service_dynamodb" {
  description       = "Allow data egress server to reach DynamoDB"
  type              = "egress"
  prefix_list_ids   = [data.terraform_remote_state.aws_sdx.outputs.vpc.prefix_list_ids.dynamodb]
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.data_egress_service.id
}

resource "aws_security_group_rule" "data_egress_dks" {
  description       = "Allow outbound requests to DKS"
  type              = "egress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  cidr_blocks       = data.terraform_remote_state.crypto.outputs.dks_subnet.cidr_blocks
  security_group_id = aws_security_group.data_egress_service.id
}

resource "aws_security_group_rule" "data_egress_nifi_egress" {
  description              = "Allow outbound requests to nifi"
  type                     = "egress"
  from_port                = var.sft_agent_port
  to_port                  = var.sft_agent_port
  protocol                 = "tcp"
  source_security_group_id = data.terraform_remote_state.snapshot_sender.outputs.stub_nifi_sg_id
  security_group_id        = aws_security_group.data_egress_service.id
}

resource "aws_security_group_rule" "data_egress_nifi_ingress" {
  description              = "Allow outbound requests to nifi"
  type                     = "ingress"
  from_port                = var.sft_agent_port
  to_port                  = var.sft_agent_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.data_egress_service.id
  security_group_id        = data.terraform_remote_state.snapshot_sender.outputs.stub_nifi_sg_id
}


