output "security_group" {
  value = {
    data_egress_server = aws_security_group.data_egress_server.id
  }
}
<<<<<<< Updated upstream

output "sft_agent_service" {
  value = {
    security_group = aws_security_group.sft_agent_service.id
    desired_count  = local.sft_agent_service_desired_count[local.environment]
  }
}
=======
>>>>>>> Stashed changes
