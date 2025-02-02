terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket = "my-terraform-state"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}

module "eks_cluster" {
  source = "../../modules/eks-cluster"

  environment         = var.environment
  region             = var.region
  cluster_name_prefix = var.cluster_name_prefix
  vpc_cidr           = var.vpc_cidr
  azs                = var.azs
    additional_tags    = var.additional_tags
}