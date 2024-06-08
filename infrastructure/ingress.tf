# # Copyright (c) HashiCorp, Inc.
# # SPDX-License-Identifier: MPL-2.0

# # provider "aws" {}

# // roles for externalDNS
# // roles for AWS Load Balancer Controller

# // user for externalDNS

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                 = data.aws_eks_cluster_auth.cluster.token
}

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

# data "helm_repository" "eks" {
#   name = "eks"
#   url  = "https://aws.github.io/eks-charts"
# }

module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.1"

  role_name = "aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "kubernetes_namespace" "aws_lb_controller" {
  metadata {
    name = "kube-system"
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.4.4"

  set {
    name  = "replicaCount"
    value = 1
  }

  set {
    name  = "clusterName"
    value = module.eks.cluster_id
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_load_balancer_controller_irsa_role.iam_role_arn
  }
}

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