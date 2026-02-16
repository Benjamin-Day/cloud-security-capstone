resource "helm_release" "alb_goapi" {
  name             = "go-api-alb"
  chart            = "./helm/alb"
  namespace        = "go-api"
  create_namespace = true
  force_update     = true
  cleanup_on_fail  = true

  set {
    name  = "name"
    value = local.go_api_alb_name
  }

  set {
    name  = "namespace"
    value = "go-api"
  }


  set {
    name  = "domain"
    value = local.api_domain
  }

  set {
    name  = "certificatearn"
    value = data.aws_acm_certificate.api.arn
  }

  set {
    name  = "service"
    value = "go-api"
  }

  set {
    name  = "port"
    value = "8080"
  }

  set {
    name  = "securityGroupId"
    value = aws_security_group.alb.id
  }

  depends_on = [helm_release.aws_lbc, aws_internet_gateway.igw, aws_eks_cluster.eks]
}

resource "time_sleep" "wait_120_seconds" {
  depends_on = [helm_release.aws_lbc]

  create_duration = "120s"
}


# Create A record with aws_lb.alb.dns_name
resource "aws_route53_record" "goapi" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = local.api_domain
  type    = "A"

  alias {
    name                   = data.aws_lb.alb.dns_name
    zone_id                = data.aws_lb.alb.zone_id
    evaluate_target_health = true
  }

  depends_on = [helm_release.alb_goapi]
}