resource "helm_release" "alb_argocd" {
  name             = "argocd-alb"
  chart            = "./helm/alb"
  namespace        = "argocd"
  create_namespace = true
  force_update     = true
  cleanup_on_fail  = true

  set {
    name  = "name"
    value = local.argocd_alb_name
  }

  set {
    name  = "namespace"
    value = "argocd"
  }

  set {
    name  = "domain"
    value = local.argocd_domain
  }

  set {
    name  = "certificatearn"
    value = data.aws_acm_certificate.argocd.arn
  }

  set {
    name  = "service"
    value = "argocd-server"
  }

  set {
    name  = "port"
    value = "80"
  }

  set {
    name  = "securityGroupId"
    value = aws_security_group.alb.id
  }

  depends_on = [helm_release.aws_lbc, aws_internet_gateway.igw, aws_eks_cluster.eks]
}

# Create A record with aws_lb.alb.dns_name
resource "aws_route53_record" "argocd" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.argocd_domain
  type    = "A"

  alias {
    name                   = data.aws_lb.alb.dns_name
    zone_id                = data.aws_lb.alb.zone_id
    evaluate_target_health = true
  }

  depends_on = [helm_release.alb_argocd]
}