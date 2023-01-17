locals {
  lt_name = format("%s-%s-lt", local.name_prefix, var.node_name)

  instance_user_data = templatefile("${path.module}/templates/user_data/node.sh.tpl", {
    cluster_name        = data.aws_eks_cluster.this.name
    kubelet_extra_args  = "--node-labels=eks-nodegroup=${var.node_name}"
    images              = var.docker_images
  })
}

resource "aws_launch_template" "this" {
  name = local.lt_name
  vpc_security_group_ids = [ data.aws_security_group.node.id ]
  user_data = base64encode(local.instance_user_data)

  enclave_options {
    enabled = var.enclave_support
  }

  image_id          = data.aws_ami.this.id
  instance_type     = var.instance_type
  key_name          = var.key_name
  ebs_optimized     = var.ebs_optimized

  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "optional"
    http_put_response_hop_limit = null
  }

  monitoring {
    enabled = var.enable_monitoring
  }

  /*
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
       volume_size = 20
    }
  }
  */

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.tags, {Name = local.lt_name})
  }

  tag_specifications {
    resource_type = "instance"
    tags =  merge(local.tags, {Name = local.lt_name })
  }

  tags = merge(local.tags,
        {
          Name        = local.lt_name
          "app:Name"  = var.node_name
          "k8s.io/cluster-autoscaler/enabled" = ""
          "k8s.io/cluster-autoscaler/${data.aws_eks_cluster.this.name}" = ""
        })

  lifecycle {
    create_before_destroy = true
  }

}