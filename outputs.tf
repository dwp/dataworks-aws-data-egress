output "security_group" {
  value = {
    data_egress_server  = aws_security_group.data_egress_server.id
    data_egress_service = aws_security_group.data_egress_service.id
  }
}

output "sft_agent_service" {
  value = {
    security_group = aws_security_group.sft_agent_service.id
    desired_count  = local.sft_agent_service_desired_count[local.environment]
  }
}

output "data_egress_ebs_cmk" {
  value = aws_kms_external_key.data_egress_ebs_cmk
}
