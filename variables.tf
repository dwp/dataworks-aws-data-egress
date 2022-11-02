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
    preprod     = "r5.2xlarge"
    production  = "r5.2xlarge"
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
  type = map(string)
  default = {
    development = "1024"
    qa          = "1024"
    integration = "1024"
    preprod     = "2048"
    production  = "2048"
  }
}

variable "fargate_memory" {
  type    = string
  default = "1024"
}

variable "receiver_cpu" {
  type    = string
  default = "512"
}

variable "data_egress_receiver_memory" {
  type = map(string)
  default = {
    development = "1024"
    qa          = "1024"
    integration = "1024"
    preprod     = "26624"
    production  = "26624"
  }
}

variable "sft_receiver_memory" {
  type = map(string)
  default = {
    development = "1024"
    qa          = "1024"
    integration = "1024"
    preprod     = "26624"
    production  = "26624"
  }
}

variable "data_egress_port" {
  type    = number
  default = 8080
}

variable "data_egress_image_version" {
  description = "pinned image versions to use"
  type        = map(string)
  default = {
    development = "0.0.63"
    qa          = "0.0.63"
    integration = "0.0.63"
    preprod     = "0.0.66"
    production  = "0.0.63"
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
  default     = "dataworks.dwp.gov.uk"
}

variable "sft_agent_port" {
  description = "port for accessing the SFT agent"
  type        = string
  default     = "8091"
}

variable "sft_agent_image_version" {
  description = "image version for the SFT agent"
  type        = map(string)
  default = {
    development = "0.0.37"
    qa          = "0.0.37"
    integration = "0.0.37"
    preprod     = "0.0.37"
    production  = "0.0.37"
  }
}

variable "test_ami" {
  description = "Defines if cluster should test untested ECS AMI"
  type        = bool
  default     = false
}

variable "task_definition_memory" {
  type = map(string)
  default = {
    development = "10240"
    qa          = "10240"
    integration = "10240"
    preprod     = "26624"
    production  = "26624"
  }
}

variable "task_definition_cpu" {
  type = map(string)
  default = {
    development = "2048"
    qa          = "2048"
    integration = "2048"
    preprod     = "4096"
    production  = "4096"
  }
}
