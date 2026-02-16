resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "7.3.3"
  force_update     = true
  cleanup_on_fail  = true

  values = [file("values/argocd.yml")]

  depends_on = [aws_eks_node_group.general, time_sleep.wait_120_seconds, helm_release.eso_argocd]
}


resource "helm_release" "app_of_apps" {
  name            = "app-of-apps"
  chart           = "./helm/app-of-apps"
  force_update    = true
  cleanup_on_fail = true

  depends_on = [helm_release.argocd]
}