output "cluster_id" {
  value = data.aws_eks_cluster.this.id
}

output "cluster_endpoint" {
  value = data.aws_eks_cluster.this.endpoint
}

output "cluster_token" {
  value = data.aws_eks_cluster_auth.this.token
}

output "launch_template_key_name" {
  value = data.aws_launch_template.node_lt.key_name
}