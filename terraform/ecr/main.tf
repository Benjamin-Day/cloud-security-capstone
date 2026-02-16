terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "<BUCKET NAME>"
    key            = "terraform/ecr.tfstate"
    region         = "us-east-1"
    dynamodb_table = "<TABLE NAME>"
    encrypt        = true
  }
}


provider "aws" {
  region = local.region
  # skip_region_validation = true
}
