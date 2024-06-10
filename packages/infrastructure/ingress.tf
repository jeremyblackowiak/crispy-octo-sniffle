# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.id]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.id]
      command     = "aws"
    }
  }
}

module "aws_load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.1"

  role_name = "aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = "${module.eks.oidc_provider}"
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "kubernetes_service_account" "service-account" {
  metadata {
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
        "app.kubernetes.io/name"= "aws-load-balancer-controller"
        "app.kubernetes.io/component"= "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = "${module.lb_role.iam_role_arn}"
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

resource "helm_release" "lb" {
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
        value = data.aws_eks_cluster.cluster.id
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

data "aws_iam_policy_document" "external_dns_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_route53_zone" "selected" {
  name = "myZone"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = data.aws_route53_zone.selected.name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_acm_certificate.cert.domain_validation_options : record.resource_record_name]

  depends_on = [aws_acm_certificate.cert]
}

resource "aws_iam_role" "external_dns" {
  name               = "external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  version    = "7.5.4"
  namespace  = "kube-system"

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.zoneType"
    value = "public"
  }

  set {
    name  = "txtOwnerId"
    value = "${data.aws_route53_zone.selected.name}"
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "aws.assumeRoleArn"
    value = aws_iam_role.external_dns.arn
  }
}