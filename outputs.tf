output "data_egress" {
  value = aws_sqs_queue.data_egress
}

output "security_group" {
  value = {
    data_egress_server = aws_security_group.data_egress_server.id
  }
}

