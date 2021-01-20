variable "assume_role" {
  type        = string
  default     = "ci"
  description = "IAM role assumed by Concourse when running Terraform"
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "data_egress_server_ec2_instance_type" {
  default = {
    development = "m5.large"
    qa          = "m5.large"
    integration = "m5.large"
    preprod     = "m5.large"
    production  = "m5.large"
  }
}
variable "data_egress_server_ebs_volume_size" {
  default = {
    development = "15000"
    qa          = "15000"
    integration = "15000"
    preprod     = "15000"
    production  = "15000"
  }
}
variable "data_egress_server_ebs_volume_type" {
  default = {
    development = "gp2"
    qa          = "gp2"
    integration = "gp2"
    preprod     = "gp2"
    production  = "gp2"
  }
}
variable "ecs_hardened_ami_id" {
  description = "The AMI ID of the latest/pinned ECS Hardened AMI Image"
  type        = string
}
variable "truststore_aliases" {
  description = "comma seperated truststore aliases"
  type        = list(string)
  default     = ["dataworks_root_ca", "dataworks_mgt_root_ca"]
}
variable "fargate_cpu" {
  default = "512"
}

variable "fargate_memory" {
  default = "512"
}

variable "receiver_cpu" {
  default = "512"
}

variable "receiver_memory" {
  default = "1024"
}

variable "data_egress_port" {
}

variable "image_versions" {
  description = "pinned image versions to use"
  default = {
    data-egress = "0.0.1"
  }
}

variable "name" {
  description = "cluster name, used in dns"
  type        = string
  default     = "data-egress"
}

variable "parent_domain_name" {
  description = "parent domain name for monitoring"
  type        = string
}
