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

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#   token                 = data.aws_eks_cluster_auth.cluster.token
# }

# resource "kubernetes_deployment" "my_app" {
#   metadata {
#     name = "my-app"
#   }
#   spec {
#     replicas = 2
#     selector {
#       match_labels = {
#         app = "my-app"
#       }
#     }
#     template {
#       metadata {
#         labels = {
#           app = "my-app"
#         }
#       }
#       spec {
#         container {
#           image = "851725465050.dkr.ecr.us-east-1.amazonaws.com/hello-repository:latest"  # replace with your Docker image
#           name  = "my-app"
#           port {
#             container_port = 3000
#           }
#         }
#       }
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

# resource "kubernetes_service" "example" {
#   metadata {
#     name = "example"
#   }
#   spec {
#     selector = {
#       App = kubernetes_deployment.my_app.metadata[0].labels.App
#     }
#     port {
#       port        = 443
#       target_port = 3000
#     }
#     type = "LoadBalancer"
#   }
# }

# resource "aws_route53_zone" "main" {
#   name = "example.com"
# }

# resource "aws_acm_certificate" "cert" {
#   domain_name       = "example.com"
#   validation_method = "DNS"
# }

# resource "aws_route53_record" "validation" {
#   name    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
#   type    = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
#   zone_id = "${aws_route53_zone.main.zone_id}"
#   records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
#   ttl     = 60
# }

# resource "aws_acm_certificate_validation" "cert" {
#   certificate_arn         = "${aws_acm_certificate.cert.arn}"
#   validation_record_fqdns = ["${aws_route53_record.validation.fqdn}"]
# }

# data "aws_lb" "my_app" {
#   name = "my-app-load-balancer-name" # replace with your load balancer name
# }

# resource "aws_route53_record" "www" {
#   name    = "www.example.com"
#   type    = "A"

#   alias {
#     name                   = data.aws_lb.my_app.dns_name
#     zone_id                = data.aws_lb.my_app.zone_id
#     evaluate_target_health = true
#   }

#   zone_id = aws_route53_zone.main.zone_id
# }