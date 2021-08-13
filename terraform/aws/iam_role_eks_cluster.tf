locals {
  iam_role_study_eks_cluster_name         = substr(replace("${local.service_prefix}_study_eks_cluster", "_", "-"), 0, 32)
  iam_role_study_eks_fargate_profile_name = substr(replace("${local.service_prefix}_study_eks_fargate_profile", "_", "-"), 0, 32)
}

resource "aws_iam_role" "study_eks_cluster" {
  name_prefix = local.iam_role_study_eks_cluster_name
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = "sts:AssumeRole"
          Principal = {
            Service = "eks.amazonaws.com"
          }
        }
      ]
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "study_eks_cluster" {
  role = aws_iam_role.study_eks_cluster.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "cloudwatch:PutMetricData"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*",
          "ec2:CreateSecurityGroup",
          "ec2:Describe*"
        ]
        Resource = "*"
      }
    ],
  })
}

resource "aws_iam_role_policy_attachment" "study_eks_cluster" {
  for_each = toset(
    [
      "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
      "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
    ]
  )

  role       = aws_iam_role.study_eks_cluster.id
  policy_arn = each.value
}

resource "aws_iam_role" "study_eks_fargate_profile" {
  name_prefix = local.iam_role_study_eks_fargate_profile_name
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = "sts:AssumeRole"
          Principal = {
            Service = "eks-fargate-pods.amazonaws.com"
          }
        }
      ]
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "study_eks_fargate_profile" {
  for_each = toset(
    [
      "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
    ]
  )

  role       = aws_iam_role.study_eks_fargate_profile.id
  policy_arn = each.value
}
