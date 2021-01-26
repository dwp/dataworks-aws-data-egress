resource "aws_iam_role" "data_egress_server" {
  name               = "DataEgressCluster"
  assume_role_policy = data.aws_iam_policy_document.data_egress_server_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_instance_profile" "data_egress_server" {
  name = "DataEgressCluster"
  role = aws_iam_role.data_egress_server.name
}

data "aws_iam_policy_document" "data_egress_server_assume_role" {
  statement {
    sid = "ECSAssumeRole"
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}


resource "aws_cloudwatch_log_group" "data_egress_server_logs" {
  name              = "/app/data-egress-server"
  retention_in_days = 180
  tags              = local.common_tags
}

resource "aws_iam_role_policy_attachment" "data_egress_cluster_monitoring_logging" {
  role       = aws_iam_role.data_egress_server.name
  policy_arn = aws_iam_policy.data_egress_cluster_monitoring_logging.arn
}

resource "aws_iam_policy" "data_egress_cluster_monitoring_logging" {
  name        = "DataEgressClusterLoggingPolicy"
  description = "Allow data egress cluster to log"
  policy      = data.aws_iam_policy_document.data_egress_cluster_monitoring_logging.json
}

data "aws_iam_policy_document" "data_egress_cluster_monitoring_logging" {
  statement {
    sid    = "AllowAccessLogGroups"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]

    resources = [aws_cloudwatch_log_group.data_egress_server_logs.arn]
  }
}

resource "aws_iam_role_policy_attachment" "ec2_for_ssm_attachment" {
  role       = aws_iam_role.data_egress_server.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "data_egress_cluster_ecs" {
  role       = aws_iam_role.data_egress_server.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "data_egress_server_ecs_cwasp" {
  role       = aws_iam_role.data_egress_server.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}



