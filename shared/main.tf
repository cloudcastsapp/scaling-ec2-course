###
# Providers
##
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.50.0"
    }
  }

  backend "s3" {
    bucket  = "cloudcasts-courses"
    key     = "best-parts/shared.tfstate"
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
  default     = "shared"
}

variable "default_region" {
  type        = string
  description = "the region this infrastructure is in"
  default     = "us-east-2"
}

variable "github_token" {
  type        = string
  description = "GitHub Personal Access Token"
  sensitive   = true
}

variable "git_url" {
  type        = string
  description = "Git Clone URL (.git)"
}

module "ci_cd" {
  source = "../modules/codebuild"

  infra_env    = var.infra_env
  git_url      = var.git_url
  github_token = var.github_token
}
