###
# Providers
##
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.41.0"
    }
  }

  backend "s3" {
    bucket  = "cloudcasts-courses"
    key     = "best-parts/terraform.tfstate"
    profile = "cloudcasts"
    region  = "us-east-2"
  }
}

provider "aws" {
  profile = "cloudcasts"
  region  = "us-east-2"
}


###
# Variables
##
variable "infra_env" {
  type        = string
  description = "infrastructure environment"
  default     = "staging"
}

variable "default_region" {
  type        = string
  description = "the region this infrastructure is in"
  default     = "us-east-2"
}

locals {
  cidr_subnets = cidrsubnets("10.0.0.0/17", 4, 4, 4, 4, 4, 4)
}

###
# Data
##
data "aws_ami" "app" {
  most_recent = true

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "tag:Component"
    values = ["app"]
  }

  filter {
    name   = "tag:Project"
    values = ["cloudcasts"]
  }

  filter {
    name   = "tag:Environment"
    values = [var.infra_env]
  }

  owners = ["self"]
}

###
# Resources
##
module "vpc" {
  source = "./modules/vpc"

  infra_env       = var.infra_env
  vpc_cidr        = "10.0.0.0/17"
  azs             = ["us-east-2a", "us-east-2b", "us-east-2c"]
  public_subnets  = slice(local.cidr_subnets, 0, 3)
  private_subnets = slice(local.cidr_subnets, 3, 6)
}

module "autoscale_web" {
  source = "./modules/ec2"

  ami             = data.aws_ami.app.id
  git_url         = "git@github.com:cloudcastsapp/cloudcasts-sample-application.git"
  infra_env       = var.infra_env
  infra_role      = "http"
  instance_type   = "t3a.small"
  security_groups = [module.vpc.internal_sg, module.vpc.web_sg]
  ssh_key_name    = "cloudcasts-forge"
}

module "autoscale_queue" {
  source = "./modules/ec2"

  ami             = data.aws_ami.app.id
  git_url         = "git@github.com:cloudcastsapp/cloudcasts-sample-application.git"
  infra_env       = var.infra_env
  infra_role      = "queue"
  instance_type   = "t3a.small"
  security_groups = [module.vpc.internal_sg]
  ssh_key_name    = "cloudcasts-forge"
}