locals {
  eks_node_group_name = replace("${local.service_prefix}_study_eks_node_group", "_", "-")
}

resource "aws_eks_node_group" "study_eks_v120" {
  depends_on = [aws_iam_role_policy_attachment.study_eks_node_group]

  cluster_name    = aws_eks_cluster.study_eks_v120.name
  node_group_name = "kube-system"
  node_role_arn   = aws_iam_role.study_eks_node_group.arn
  subnet_ids      = module.vpc_main.private_subnets

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  instance_types = ["t3.micro"]

  tags = { Name = local.eks_node_group_name }
}
