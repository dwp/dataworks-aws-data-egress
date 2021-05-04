output "data_egress" {
  value = aws_sqs_queue.data_egress
}

output "security_group" {
  value = {
    data_egress_server = aws_security_group.data_egress_server.id
  }
}

output "sft_agent_service" {
  value = {
    security_group = aws_security_group.sft_agent_service.id
    desired_count  = local.sft_agent_service_desired_count
  }
}