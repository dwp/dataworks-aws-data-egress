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
variable "al2_hardened_ami_id" {
  description = "The AMI ID of the latest/pinned Hardened AMI AL2 Image"
  type        = string
}
variable "truststore_aliases" {
  description = "comma seperated truststore aliases"
  type        = list(string)
  default     = ["dataworks_root_ca", "dataworks_mgt_root_ca"]
}
