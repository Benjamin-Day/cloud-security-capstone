resource "aws_ecr_repository" "go_api" {
  name = "go-api"

  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  # checkov:skip=CKV_AWS_136:Ensure that ECR repositories are encrypted using KMS
  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "go_api" {
  repository = aws_ecr_repository.go_api.name

  policy = file("./policies/lifecycle.json")
}