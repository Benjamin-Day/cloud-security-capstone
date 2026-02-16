# Pod identity for ESO 
resource "aws_iam_role" "eso" {
  name = "${local.eks_name}-eso"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      Effect = "Allow"
      Principal = {
        Service = [
          "pods.eks.amazonaws.com"
        ]
      }
    }]
  })
}

resource "aws_iam_role" "eso_workload" {
  name = "${local.eks_name}-eso-workload"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      Effect = "Allow"
      Principal = {
        AWS = aws_iam_role.eso.arn
      }
    }]
  })
}


resource "aws_iam_policy" "eso_workload" {
  policy = templatefile("./policies/ExternalSecretsOperator.json", {
    account_id = data.aws_caller_identity.current.account_id
    region     = local.region
  })
  name = "ExternalSecretsOperator"
}

resource "aws_iam_role_policy_attachment" "eso_workload" {
  policy_arn = aws_iam_policy.eso_workload.arn
  role       = aws_iam_role.eso_workload.name
}

resource "aws_eks_pod_identity_association" "eso" {
  cluster_name    = aws_eks_cluster.eks.name
  role_arn        = aws_iam_role.eso.arn
  namespace       = "external-secrets"
  service_account = "external-secrets"
}

resource "helm_release" "eso" {
  name = "external-secrets"

  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  version          = "0.9.20"
  create_namespace = true
  force_update     = true
  cleanup_on_fail  = true

  depends_on = [aws_eks_node_group.general]
}

resource "helm_release" "eso_argocd" {
  name = "eso-argocd"

  chart           = "./helm/secretstore"
  namespace       = "external-secrets"
  force_update    = true
  cleanup_on_fail = true

  set {
    name  = "roleArn"
    value = aws_iam_role.eso_workload.arn
  }

  depends_on = [helm_release.eso]
}