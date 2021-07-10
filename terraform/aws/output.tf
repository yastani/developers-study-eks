output "endpoint" {
  value = aws_eks_cluster.consul_v120.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.consul_v120.certificate_authority[0].data
}
