terraform {
  required_version = ">= 1.5"
  #backend "s3" {
  #  bucket = "terraform-state-rizky"
  #  key    = "aws-vpc-baseline/terraform.tfstate"
  #  region = "ap-southeast-3"
  #}
  backend "local" {}
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

provider "aws" {
  region = "ap-southeast-3"
}

module "vpc" {
  source    = "./modules/vpc"
  cidr      = var.vpc_cidr
  name      = var.vpc_name
  az_count  = var.vpc_az_count
  host_bits = var.vpc_host_bits
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnet_ids" {
  value = {
    public = module.vpc.public_subnet_ids
    # private = module.vpc.private_subnet_ids
  }
}


