terraform {
  required_version = "~> 0.15"

  backend "s3" {
    bucket      = "yastani-ymm-lab-tfstates"
    key         = "terraform.tfstate"
    region      = "ap-northeast-1"
    encrypt     = true
    max_retries = 1
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
    kubernetes = {
      version = "~> 2.3"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"

  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/terraform"
  }

  default_tags {
    tags = {
      Terraform = true
      Owner       = "yastani"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/terraform"
  }

  default_tags {
    tags = {
      Terraform = true
      Owner       = "yastani"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = sensitive(base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data))
  token                  = data.aws_eks_cluster_auth.cluster.token
}
