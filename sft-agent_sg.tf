resource "aws_security_group" "sft_agent_service" {
  name        = "sft_agent_service"
  description = "Control access to and from data egress service"
  vpc_id      = data.terraform_remote_state.aws_sdx.outputs.vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = "sft_agent_service"
    }
  )
}

resource "aws_security_group_rule" "sft_agent_service_s3_https" {
  description       = "Access to S3 https"
  type              = "egress"
  prefix_list_ids   = [data.terraform_remote_state.aws_sdx.outputs.vpc.prefix_list_ids.s3]
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.sft_agent_service.id
}

resource "aws_security_group_rule" "sft_agent_service_s3_http" {
  description       = "Access to S3 http"
  type              = "egress"
  prefix_list_ids   = [data.terraform_remote_state.aws_sdx.outputs.vpc.prefix_list_ids.s3]
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  security_group_id = aws_security_group.sft_agent_service.id
}

resource "aws_security_group_rule" "sft_agent_service_to_crown" {
  description       = "Allow SFT agent to access crown"
  type              = "egress"
  protocol          = "tcp"
  from_port         = 8091
  to_port           = 8091
  security_group_id = aws_security_group.sft_agent_service.id
  cidr_blocks       = [data.terraform_remote_state.aws_sdx.outputs.vpc.vpc.cidr_block]
}
