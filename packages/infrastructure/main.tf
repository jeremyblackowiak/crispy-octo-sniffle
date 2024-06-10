# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

// This file creates the VPC and EKS cluster resources

provider "aws" {}

locals {
  cluster_name = "test-eks-${random_string.suffix.result}"
}

locals {
  name = "jeremy-infra" ## You must use my name

  tags = {
    jeremy = "did-this" ## And my tag
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

// Create a slim VPC with properly tagged subnets for AWS Load Balancer Controller
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "main"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.0.0/19", "10.0.32.0/19"]
  public_subnets  = ["10.0.64.0/19", "10.0.96.0/19"]

  enable_nat_gateway     = true
  single_nat_gateway     = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    "type" = "public"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "type" = "internal"
  }

  tags = {
    Environment = "test"
  }
}

// A too-open SG for testing purposes
resource "aws_security_group" "eks" {
    name        = "eks sg"
    description = "Allow traffic"
    vpc_id      = module.vpc.vpc_id

    ingress {
      description      = "everything for testing purposes"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
      "kubernetes.io/cluster/${local.cluster_name}": "owned"
    }
  }

// The EKS cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"
  depends_on = [ module.vpc ]
  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access           = true
  cluster_endpoint_private_access = true
  enable_cluster_creator_admin_permissions = true
  cluster_additional_security_group_ids = [aws_security_group.eks.id]

  enable_irsa = true

  eks_managed_node_group_defaults = {
    disk_size = 30
  }

  eks_managed_node_groups = {
    nodes = {
      desired_size = 3
      min_size     = 3
      max_size     = 3

      instance_types = ["t3.micro"]
    }
  }

}

// IAM role policy for EKS admins
module "allow_eks_access_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.3.1"

  name          = "allow-eks-access"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

// IAM role for EKS admins
module "eks_admins_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.3.1"

  role_name         = "eks-admin"
  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [module.allow_eks_access_iam_policy.arn]

  trusted_role_arns = [
    "arn:aws:iam::${module.vpc.vpc_owner_id}:root"
  ]
}

// Associating the piolicy with the role
module "allow_assume_eks_admins_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.3.1"

  name          = "allow-assume-eks-admin-iam-role"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = module.eks_admins_iam_role.iam_role_arn
      },
    ]
  })
}

// IAM group for EKS admins
module "eks_admins_iam_group" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "5.3.1"

  name                              = "eks-admin"
  attach_iam_self_management_policy = false
  create_group                      = true
  group_users                       = ["ciUser"]
  custom_group_policy_arns          = [module.allow_assume_eks_admins_iam_policy.arn]
}