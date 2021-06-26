##################################################
# Predefined VPC module
# https://github.com/terraform-aws-modules/terraform-aws-vpc
##################################################
locals {
  vpc_name = replace("${var.service_prefix}_vpc", "_", "-")

  # ["10.0.0.0/22", "10.0.4.0/22", "10.0.8.0/22"]
  public_subnets = [
    cidrsubnet(var.vpc_cidr, 6, 0),
    cidrsubnet(var.vpc_cidr, 6, 1),
    cidrsubnet(var.vpc_cidr, 6, 2)
  ]
  # ["10.0.12.0/22", "10.0.16.0/22", "10.0.20.0/22"]
  private_subnets = [
    cidrsubnet(var.vpc_cidr, 6, 3),
    cidrsubnet(var.vpc_cidr, 6, 4),
    cidrsubnet(var.vpc_cidr, 6, 5)
  ]
  # ["10.0.24.0/22", "10.0.28.0/22", "10.0.32.0/22"]
  database_subnets = [
    cidrsubnet(var.vpc_cidr, 6, 6),
    cidrsubnet(var.vpc_cidr, 6, 7),
    cidrsubnet(var.vpc_cidr, 6, 8)
  ]
  # ["10.0.36.0/22", "10.0.40.0/22", "10.0.44.0/22"]
  intra_subnets = [
    cidrsubnet(var.vpc_cidr, 6, 9),
    cidrsubnet(var.vpc_cidr, 6, 10),
    cidrsubnet(var.vpc_cidr, 6, 11)
  ]
}

module "vpc_main" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  # VPC
  name                 = local.vpc_name
  cidr                 = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  # Subnets
  azs                                = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  create_database_subnet_group       = true
  create_database_subnet_route_table = true
  public_subnets                     = local.public_subnets
  private_subnets                    = local.private_subnets
  database_subnets                   = local.database_subnets
  intra_subnets                      = local.intra_subnets

  # Internet Gateway
  create_igw = true
  # NAT Gateway
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = true
  # S2S VPN
  enable_vpn_gateway = false
}
