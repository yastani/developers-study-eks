locals {
  eks_cluster_name         = replace("${local.service_prefix}_study_eks_cluster", "_", "-")
  eks_fargate_profile_name = replace("${local.service_prefix}_study_eks_fargate_profile", "_", "-")
}

resource "aws_cloudwatch_log_group" "study_eks_cluster" {
  name              = "/aws/eks/cluster/${local.eks_cluster_name}"
  retention_in_days = 7
}

resource "aws_kms_key" "study_eks_cluster" {
  is_enabled               = true
  enable_key_rotation      = false
  description              = "This KMS Key is used in the Encryption of EKS."
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days  = 7
}

resource "aws_kms_alias" "study_eks_cluster" {
  name_prefix   = "alias/eks/cluster/${local.eks_cluster_name}"
  target_key_id = aws_kms_key.study_eks_cluster.key_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_cluster" "study_eks_v120" {
  depends_on = [
    aws_cloudwatch_log_group.study_eks_cluster,
    aws_iam_role_policy_attachment.study_eks_cluster,
    aws_iam_role_policy_attachment.study_eks_fargate_profile
  ]

  name     = local.eks_cluster_name
  role_arn = aws_iam_role.study_eks_cluster.arn
  version  = "1.20"
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  vpc_config {
    subnet_ids              = module.vpc_main.private_subnets
    security_group_ids      = []
    public_access_cidrs     = ["0.0.0.0/0"]
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  kubernetes_network_config {
    service_ipv4_cidr = "172.20.0.0/16"
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.study_eks_cluster.arn
    }
  }
}

resource "aws_eks_fargate_profile" "study_eks_v120" {
  depends_on = [
    aws_iam_role.study_eks_fargate_profile,
    aws_eks_cluster.study_eks_v120
  ]

  fargate_profile_name   = local.eks_fargate_profile_name
  cluster_name           = aws_eks_cluster.study_eks_v120.name
  pod_execution_role_arn = aws_iam_role.study_eks_fargate_profile.arn
  subnet_ids             = module.vpc_main.private_subnets

  selector {
    namespace = local.service_prefix
    labels = {
      ENV = var.env
    }
  }
}
