terraform {
  required_version = ">= 0.14.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 3.31"
    }
    kubernetes = {
      source  = "registry.terraform.io/hashicorp/kubernetes"
      version = "~> 2.1.0"
    }
  }
}

provider "aws" {
  region      = var.context.aws_region
  profile     = var.context.aws_profile
  shared_credentials_file = var.context.aws_credentials_file
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_eks_cluster" "this" {
  name = format("%s-eks", local.name_prefix)
}

data "aws_eks_cluster_auth" "this" {
  name = data.aws_eks_cluster.this.id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.this.token
  load_config_file       = false
}
