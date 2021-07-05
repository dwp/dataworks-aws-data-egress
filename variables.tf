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
  type = map(string)
  default = {
    development = "m5.xlarge"
    qa          = "m5.xlarge"
    integration = "m5.xlarge"
    preprod     = "m5.xlarge"
    production  = "m5.xlarge"
  }
}
variable "data_egress_server_ebs_volume_size" {
  type = map(string)
  default = {
    development = "1000"
    qa          = "1000"
    integration = "1000"
    preprod     = "1000"
    production  = "15000"
  }
}
variable "data_egress_server_ebs_volume_type" {
  type = map(string)
  default = {
    development = "gp3"
    qa          = "gp3"
    integration = "gp3"
    preprod     = "gp3"
    production  = "gp3"
  }
}
variable "ecs_hardened_ami_id" {
  description = "The AMI ID of the latest/pinned ECS Hardened AMI Image"
  type        = string
}
variable "truststore_aliases" {
  description = "comma seperated truststore aliases"
  type        = list(string)
  default     = ["dataworks_root_ca", "dataworks_mgt_root_ca", "sdx1", "sdx2"]
}
variable "fargate_cpu" {
  type    = string
  default = "512"
}

variable "fargate_memory" {
  type    = string
  default = "512"
}

variable "receiver_cpu" {
  type    = string
  default = "512"
}

variable "receiver_memory" {
  default = "1024"
  type    = string
}

variable "data_egress_port" {
  type    = number
  default = 8080
}

variable "data_egress_image_version" {
  description = "pinned image versions to use"
  type        = string
  default     = "0.0.33"
}

variable "name" {
  description = "cluster name, used in dns"
  type        = string
  default     = "data-egress"
}

variable "parent_domain_name" {
  description = "parent domain name for monitoring"
  type        = string
  default     = "dataworks.dwp.gov.uk"
}

variable "sft_agent_port" {
  description = "port for accessing the SFT agent"
  type        = string
  default     = "8091"
}

variable "sft_agent_image_version" {
  description = "image version for the SFT agent"
  type        = string
  default     = "0.0.30"
}
