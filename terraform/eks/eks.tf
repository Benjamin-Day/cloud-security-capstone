resource "aws_iam_role" "eks" {
  name = "${local.env}-eks-cluster"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_eks_cluster" "eks" {
  name     = "${local.env}-eks"
  version  = local.eks_version
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_cluster.id]

    subnet_ids = [
      aws_subnet.private_zone_1.id,
      aws_subnet.private_zone_2.id
    ]
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  # checkov:skip=CKV_AWS_37: "Ensure Amazon EKS control plane logging is enabled for all log types"
  # Enabling logging is cost prohibitive for non-enterprise users

  # checkov:skip=CKV_AWS_39: "Ensure Amazon EKS public endpoint disabled"
  # Disabling public access would mean that GitHub Actions would have to be hosted inside the cluster 
  # to apply terraform or be hosted on the same ip address so that the public ip address could be whitelisted. 
  # Also an EKS private hosted zone and private endpoint would need to be deployed. Unsure of the financial cost.

  # checkov:skip=CKV_AWS_38: "Ensure Amazon EKS public endpoint not accessible to 0.0.0.0/0"
  # See above. Public access for all IP addresses is required. Per AWS this is still 
  # considered secure because it is backed by AWS IAM.

  # checkov:skip=CKV_AWS_58: "Ensure EKS Cluster has Secrets Encryption Enabled"
  # Does not provide much additional protection.

  depends_on = [aws_iam_role_policy_attachment.eks]
}

resource "aws_eks_addon" "pod_identity" {
  cluster_name  = aws_eks_cluster.eks.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.2.0-eksbuild.1"
}

resource "aws_iam_openid_connect_provider" "irsa" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.irsa.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_eks_access_entry" "manager" {
  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = join("", data.aws_iam_roles.cluster_admin.arns)
  kubernetes_groups = ["cluster-admin"]
}