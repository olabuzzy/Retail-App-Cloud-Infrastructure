provider "aws" {
  region = local.region
}

terraform {
  required_version = ">=1.0"

  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~>6.13.0"
    }
  }
  backend "s3" {
    bucket         = "project-bedrock-tfstate"
    key            = "infra/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "project-bedrock-locks"
  }
}

