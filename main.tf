locals {
  node_group_name = format("%s-%s-node",data.aws_eks_cluster.this.id, var.node_name)
}

resource "null_resource" "update_eks_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${data.aws_eks_cluster.this.name}"
    environment = {
      AWS_PROFILE = var.context.aws_profile
    }
  }
}

resource "aws_eks_node_group" "node" {
  cluster_name    = data.aws_eks_cluster.this.id

  node_group_name = local.node_group_name
  node_role_arn   = data.aws_iam_role.node.arn
  subnet_ids      = data.aws_subnet_ids.node.ids

  scaling_config {
    desired_size  = var.asg_desired_capacity
    min_size      = var.asg_min_capacity
    max_size      = var.asg_max_capacity
  }

  capacity_type   = "ON_DEMAND"
  instance_types  = null # if use launch-template then must be null
  release_version = null
  ami_type        = null
  disk_size       = null

  remote_access {

  }

  launch_template {
    id            = aws_launch_template.this.id
    version       = aws_launch_template.this.default_version
  }

  version         = null
  labels          = {}

  tags            = merge(local.tags, {Name = local.node_group_name})

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config.0.desired_size]
  }

}