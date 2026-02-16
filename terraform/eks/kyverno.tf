# Roles for Kyverno. Note that Pod Identity associations are relatively new as of creation (June 2024).
# Kyverno does not yet support it so IRSA are used.

resource "aws_iam_role" "kyverno-notation-aws" {
  name = "kyverno-notation-aws"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid    = ""
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.irsa.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${aws_iam_openid_connect_provider.irsa.url}:sub" = "system:serviceaccount:kyverno-notation-aws:kyverno-notation-aws"
          "${aws_iam_openid_connect_provider.irsa.url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "kyverno_ecr_policy" {
  role       = aws_iam_role.kyverno-notation-aws.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "kyverno_custom_policy" {
  name = "kyverno-custom-policy"
  role = aws_iam_role.kyverno-notation-aws.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VisualEditor0"
        Effect = "Allow"
        Action = [
          "signer:GetRevocationStatus"
        ]
        Resource = "arn:aws:signer:us-east-1:${var.aws_account_id}:/signing-profiles/capstone_eks"
      }
    ]
  })
}