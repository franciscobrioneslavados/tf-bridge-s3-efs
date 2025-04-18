provider "aws" {
  region  = var.aws_region
  alias   = "" # Default provider
  profile = "" # Default profile
  default_tags {
    tags = {
      "Environment" = var.environment
      "ManagedBy"   = var.managed_by
      "Owner"       = var.owner
      "Project"     = var.project
    }
  }
}

terraform {
  required_version = ">= 0.13"
  backend "s3" {
    bucket = ""                  # Bucket name
    key    = "terraform.tfstate" # Path to the state file
    region = ""                  # AWS region
    # dynamodb_table = "terraform-locks"
    encrypt = false
    # use_lockfile = true # Native s3 locking
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5" #5.94.1
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4" # 4.0
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2" #2.5.2
    }
  }
}