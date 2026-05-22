output "eks_name" {
  value = aws_eks_cluster.eks.name
}

output "oidc_url" {
  value = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}