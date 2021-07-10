locals {
  iam_role_eks_node_group_name = substr(replace("${local.service_prefix}_eks_node_group", "_", "-"), 0, 32)
}

resource "aws_iam_role" "eks_node_group" {
  name_prefix = local.iam_role_eks_node_group_name
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = "sts:AssumeRole"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        }
      ]
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "eks_node_group" {
  for_each = toset(
    [
      "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
      "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    ]
  )

  role       = aws_iam_role.eks_node_group.id
  policy_arn = each.value
}
