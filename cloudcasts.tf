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
    bucket = "cloudcasts-courses"
    key    = "best-parts/terraform.tfstate"
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
  default     = "production"
}

variable "default_region" {
  type = string
  description = "the region this infrastructure is in"
  default = "us-east-2"
}

locals {
    cidr_subnets = cidrsubnets("10.0.0.0/17", 4, 4, 4, 4, 4, 4)
}

###
# Data
##

###
# Resources
##
module "vpc" {
  source = "./modules/vpc"

  infra_env = var.infra_env
  vpc_cidr = "10.0.0.0/17"
  azs = ["us-east-2a", "us-east-2b", "us-east-2c"]
  public_subnets = slice(local.cidr_subnets, 0, 3)
  private_subnets = slice(local.cidr_subnets, 3, 6)
}
