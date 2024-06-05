# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {}

# Filter out local zones, which are not currently supported 
# with managed node groups
data "aws_availability_zones" "available" {}

locals {
  cluster_name = "education-eks-${random_string.suffix.result}"
}

locals {
  name = "jeremy-infra"
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    jeremy = "did-this"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  intra_subnet_tags = {
    "type" = "intra"
  }

  tags = local.tags
}

output "private_subnets" {
  description = "The private subnets"
  value       = module.vpc.private_subnets
}

output "intra_subnets" {
  description = "The private subnets"
  value       = module.vpc.intra_subnets
}

resource "aws_iam_role" "eks-cluster" {
  name = "eks-cluster-${local.cluster_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "amazon-eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster.name
}

resource "aws_iam_role" "example" {
  name = "eks-fargate-profile-example"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.example.name
}

# resource fargate_profile "example" {
#   cluster_name = module.eks.cluster_id
#   fargate_profile_name = "example"
#   pod_execution_role_arn = aws_iam_role.example.arn
#   subnet_ids = module.vpc.private_subnets
#   namespace = "default"
#   selectors {
#     namespace = "default"
#   }
# }

# data "subnet_ids" "private" {
#   vpc_id = module.vpc.vpc_id
#   tags = {
#     "kubernetes.io/role/internal-elb" = "1"
#   }  
# }

# data "subnet_ids" "intra" {
#   vpc_id = module.vpc.vpc_id
#   tags = {
#     "kubernetes.io/role/internal-elb" = "1"
#   }  
# }

# output "private_subnet_ids" {
#   description = "The private subnet IDs"
#   value       = data.subnet_ids.private.ids
  
# }

data "aws_subnet" "private" {
  for_each = toset(module.vpc.private_subnets)
  id = each.value
}

output "private_subnet_ids" {
  description = "The private subnet IDs"
  value       = [for subnet in data.aws_subnet.private : subnet.id]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"
  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        computeType = "fargate"
      })
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = ["subnet-047cfc38be1b76239", "subnet-0b58727fa8ad9ff47", "subnet-08dfff2c0a7400641"]
  control_plane_subnet_ids = ["subnet-05ef8cbb5d3603a3e", "subnet-05707e443a05c42f5", "subnet-05a74ebfc6655bd7d"]

  create_cluster_security_group = false
  create_node_security_group    = false

  fargate_profile_defaults = {
    iam_role_additional_policies = {
      additional = aws_iam_policy.additional.arn
    }
  }

  fargate_profiles = {
    example = {
      name = "example"
      selectors = [
        {
          namespace = "backend"
          labels = {
            Application = "backend"
          }
        },
        {
          namespace = "app-*"
          labels = {
            Application = "app-wildcard"
          }
        }
      ]

      # Using specific subnets instead of the subnets supplied for the cluster itself
      subnet_ids = [module.vpc.private_subnets[1]]

      tags = {
        Owner = "secondary"
      }
    }
    kube-system = {
      selectors = [
        { namespace = "kube-system" }
      ]
    }
  }

}
  # eks_managed_node_group_defaults = {
  #   ami_type = "AL2_x86_64"

  # }

  # eks_managed_node_groups = {
  #   one = {
  #     name = "node-group-1"

  #     instance_types = ["t3.small"]

  #     min_size     = 1
  #     max_size     = 1
  #     desired_size = 1
  #   }

  #   two = {
  #     name = "node-group-2"

  #     instance_types = ["t3.small"]

  #     min_size     = 1
  #     max_size     = 1
  #     desired_size = 1
  #   }
  # }



# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "aws_iam_policy" "additional" {
  name = "${local.cluster_name}-additional"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
