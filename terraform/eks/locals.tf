locals {
  env             = "capstone"
  region          = "ca-west-1"
  zone_1          = "ca-west-1b"
  zone_2          = "ca-west-1c"
  eks_name        = "capstone-eks"
  eks_version     = "1.30"
  go_api_alb_name = "go-api-eks-alb"
  argocd_alb_name = "argocd-eks-alb"
  domain          = "<DOMAIN>"
  argocd_domain   = "argocd.<DOMAIN>"
  api_domain      = "api.<DOMAIN>"
}