# # Copyright (c) HashiCorp, Inc.
# # SPDX-License-Identifier: MPL-2.0

# # provider "aws" {}

# // roles for externalDNS
# // roles for AWS Load Balancer Controller

# // user for externalDNS

# data "aws_eks_cluster" "cluster" {
#   name = module.eks.cluster_id
# }

# data "aws_eks_cluster_auth" "cluster" {
#   name = module.eks.cluster_id
# }

# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.cluster.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
#       command     = "aws"
#     }
#   }
# }

# resource "kubernetes_namespace" "aws_lb_controller" {
#   metadata {
#     name = "kube-system"
#   }
# }

# resource "helm_release" "aws_lb_controller" {
#   name       = "aws-load-balancer-controller"
#   namespace  = kubernetes_namespace.aws_lb_controller.metadata[0].name
#   repository = data.helm_repository.eks.metadata[0].name
#   chart      = "aws-load-balancer-controller"
#   version    = "1.2.3"  # replace with the version you want to install

#   set {
#     name  = "clusterName"
#     value = module.eks.cluster_name  # replace with your cluster name
#   }

#   set {
#     name  = "serviceAccount.create"
#     value = "false"
#   }

#   set {
#     name  = "serviceAccount.name"
#     value = "aws-load-balancer-controller"
#   }
# }