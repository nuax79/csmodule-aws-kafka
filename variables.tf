variable "context" {
  type = object({
    aws_credentials_file    = string # describe a path to locate a credentials from access aws cli
    aws_profile             = string # describe a specifc profile to access a aws cli
    aws_region              = string # describe default region to create a resource from aws
    region_alias            = string # region alias or AWS
    project                 = string # project name is usally account's project name or platform name
    environment             = string # Runtime Environment such as develop, stage, production
    env_alias               = string # Runtime Environment such as develop, stage, production
    owner                   = string # project owner
    team                    = string # Team name of Devops Transformation
    domain                  = string # public domain name (ex, customer.co.kr)
  })
}

variable "namespace" {
  description = "kubernetes namespace for kafka"
  type        = string
  default     = "kafka"
}

variable "ami_name" {
  description = "AMI name"
  type        = string
}

variable "instance_type" {
  description = "ec2 instance type"
  type        = string
}

variable "ebs_optimized" {
  description = "ebs optimized"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "enable monitoring"
  type        = bool
  default     = false
}

variable "enclave_support" {
  description = "enclave support"
  type        = bool
  default     = false
}

variable "key_name" {
  description = "key_name"
  type        = string
  default     = null
}

variable "node_name" {
  description = "EKS node group name"
  type        = string
}

variable "asg_desired_capacity" {
  description = "asg_desired_capacity"
  type        = number
}

variable "asg_min_capacity" {
  description = "asg_min_capacity"
  type        = number
}

variable "asg_max_capacity" {
  description = "asg_max_capacity"
  type        = number
}

variable "docker_images" {
  description = "Docker images to be downloaded from public repository like hub.docker.com"
  type        = list(string)
  default     = []
}

variable "kafka" {
  description = ""
  type = object({
    image_name    = string
    image_version = string
    service_name  = string
    heap_opts     = string
    daemon_opts   = string
  })
}

locals {
  account_id            = data.aws_caller_identity.current.account_id
  name_prefix           = format("%s-%s%s", var.context.project, var.context.region_alias, var.context.env_alias)
  eks_context_name      = format("arn:aws:eks:%s:%s:cluster/%s-eks", var.context.aws_region, local.account_id, local.name_prefix)
  toolchain_repository  = "harbor.toolchain/tools"

  tags = {
    Project = var.context.project
    Environment = var.context.environment
    Team = var.context.team
    Owner = var.context.owner
  }
}
