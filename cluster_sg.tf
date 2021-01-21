resource "aws_security_group" "data_egress_server" {
  name        = "data_egress_server"
  description = "Control access to and from data egress server"
  vpc_id      = data.terraform_remote_state.aws_sdx.outputs.vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      "Name" = local.data_egress_server_name
    }
  )
}

resource "aws_security_group_rule" "data_egress_server_s3" {
  description       = "Allow data egress server to reach S3"
  type              = "egress"
  prefix_list_ids   = [data.terraform_remote_state.aws_sdx.outputs.vpc.prefix_list_ids.s3]
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.data_egress_server.id
}

resource "aws_security_group_rule" "data_egress_server_dynamodb" {
  description       = "Allow data egress server to reach DynamoDB"
  type              = "egress"
  prefix_list_ids   = [data.terraform_remote_state.aws_sdx.outputs.vpc.prefix_list_ids.dynamodb]
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.data_egress_server.id
}

resource "aws_security_group_rule" "egress_data_egress_server_internet" {
  description              = "Allow data egress server access to Internet Proxy (for ACM-PCA)"
  type                     = "egress"
  source_security_group_id = data.terraform_remote_state.aws_sdx.outputs.internet_proxy.sg
  protocol                 = "tcp"
  from_port                = 3128
  to_port                  = 3128
  security_group_id        = aws_security_group.data_egress_server.id
}

resource "aws_security_group_rule" "ingress_data_egress_server_internet" {
  description              = "Allow data egress server access to Internet Proxy (for ACM-PCA)"
  type                     = "ingress"
  source_security_group_id = aws_security_group.data_egress_server.id
  protocol                 = "tcp"
  from_port                = 3128
  to_port                  = 3128
  security_group_id        = data.terraform_remote_state.aws_sdx.outputs.internet_proxy.sg
}

resource "aws_security_group_rule" "egress_data_egress_server_vpc_endpoint" {
  description              = "Allow data egress server access to VPC endpoints"
  type                     = "egress"
  source_security_group_id = data.terraform_remote_state.aws_sdx.outputs.vpc.interface_vpce_sg_id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  security_group_id        = aws_security_group.data_egress_server.id
}

resource "aws_security_group_rule" "ingress_data_egress_server_vpc_endpoint" {
  description              = "Allow data egress server access to VPC endpoints"
  type                     = "ingress"
  source_security_group_id = aws_security_group.data_egress_server.id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  security_group_id        = data.terraform_remote_state.aws_sdx.outputs.vpc.interface_vpce_sg_id
}

resource "aws_security_group_rule" "data_egress_dks" {
  description       = "Allow outbound requests to DKS"
  type              = "egress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  cidr_blocks       = data.terraform_remote_state.crypto.outputs.dks_subnet.cidr_blocks
  security_group_id = aws_security_group.data_egress_server.id
}

//Looks like there already exists another rule to allow this CIDR block and below ingress rule is failing because of a TF bug https://github.com/hashicorp/terraform/pull/2376
//resource "aws_security_group_rule" "data_ingress_dks" {
//  provider          = aws.management-crypto
//  description       = "Allow inbound requests to DKS from data egress server"
//  type              = "ingress"
//  from_port         = 8443
//  to_port           = 8443
//  protocol          = "tcp"
//  cidr_blocks       = aws_subnet.sdx_connectivity.*.cidr_block
//  security_group_id = data.terraform_remote_state.crypto.outputs.dks_sg_id[local.environment]
//}
