data "aws_vpc" "this" {
  filter {
    name = "tag:Name"
    values = [ "${local.name_prefix}-vpc" ]
  }
}

data "aws_subnet_ids" "node" {
  vpc_id = data.aws_vpc.this.id

  filter {
    name   = "tag:kubernetes.io/cluster/${local.name_prefix}-eks"
    values = ["shared"]
  }

  filter {
    name   = "tag:kubernetes.io/role/internal-elb"
    values = ["1"]
  }
}

data "aws_ami" "this" {
  most_recent = true
  owners = ["self"]

  filter {
    name   = "tag:Name"
    values = [ format("%s*", var.ami_name) ]
  }
}

data "aws_iam_role" "node" {
  name = format("%sEksWorkerEC2Role", var.context.project)
}

data "aws_security_group" "node" {
  name = format("%s-worker-sg", local.name_prefix)
}

data "aws_alb" "this" {
  name = format("%s-ingress-alb", local.name_prefix)
}

resource "null_resource" "describe_node_launch_template" {
  provisioner "local-exec" {
    command = <<EOT
EKS_NODE_GROUP_NAME=$(aws eks list-nodegroups --cluster-name ${data.aws_eks_cluster.this.name} --query 'nodegroups[0]' --out text)
aws eks describe-nodegroup --cluster ${data.aws_eks_cluster.this.name} --nodegroup $EKS_NODE_GROUP_NAME \
  --query 'nodegroup.launchTemplate.id' --out text > ${path.module}/NODE_LAUNCH_TEMPLATE.id
sleep 1
EOT
    environment = {
      AWS_PROFILE = var.context.aws_profile
      AWS_REGION  = var.context.aws_region
    }
  }
}

data "local_file" "node_lt" {
  filename = "${path.module}/NODE_LAUNCH_TEMPLATE.id"
  depends_on = [null_resource.describe_node_launch_template]
}

data "aws_launch_template" "node_lt" {
  id = chomp(data.local_file.node_lt.content)
}
