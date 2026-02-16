data "aws_acm_certificate" "api" {
  domain   = local.api_domain
  statuses = ["ISSUED"]
}

data "tls_certificate" "irsa" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

data "aws_acm_certificate" "argocd" {
  domain   = local.argocd_domain
  statuses = ["ISSUED"]
}

# Get domain of application load balancer
data "aws_lb" "alb" {
  tags = {
    Name = "external"
  }
  depends_on = [time_sleep.wait_120_seconds]
}

# Get the zone id of the primary domain record
data "aws_route53_zone" "zone" {
  name = local.domain
}

data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

data "aws_iam_roles" "cluster_admin" {
  name_regex = ".*ClusterAdmin.*"
}

data "aws_caller_identity" "current" {}