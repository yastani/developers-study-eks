provider "kubernetes" {
  host                   = data.aws_eks_cluster.consul_v120.endpoint
  cluster_ca_certificate = sensitive(base64decode(data.aws_eks_cluster.consul_v120.certificate_authority.0.data))
  token                  = data.aws_eks_cluster_auth.consul_v120.token
  load_config_file       = false
}

data "aws_eks_cluster" "consul_v120" {
  name = local.eks_cluster_name
}

data "aws_eks_cluster_auth" "consul_v120" {
  name = local.eks_cluster_name
}

data "template_file" "kube_config" {
  template = file("${path.module}/template/kube_config.yaml")

  vars = {
    kubeconfig_name     = "eks_${aws_eks_cluster.consul_v120.name}"
    clustername         = aws_eks_cluster.consul_v120.name
    endpoint            = data.aws_eks_cluster.consul_v120.endpoint
    cluster_auth_base64 = data.aws_eks_cluster.consul_v120.certificate_authority[0].data
    role_arn            = "arn:aws:iam::${var.aws_account_id}:role/terraform"
  }
}

resource "local_file" "kube_config" {
  content  = data.template_file.kube_config.rendered
  filename = pathexpand("~/.kube/config")
}

data "external" "thumbprint" {
  depends_on = [aws_eks_cluster.consul_v120]

  program = ["${path.module}/cmd/oidc_thumbprint.sh", var.region]
}

resource "aws_iam_openid_connect_provider" "consul_v120" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.external.thumbprint.result.thumbprint]
  url             = data.aws_eks_cluster.consul_v120.identity[0].oidc[0].issuer
}
