resource "local_file" "kafka_ns" {
  content = templatefile("${path.module}/templates/kubernetes/kafka/kafka-ns.yaml.tpl",  {
    namespace             = var.namespace
  })
  filename = "${path.module}/kubernetes/kafka/kafka-ns.yaml"
}

resource "local_file" "kafka_pv" {
  content = templatefile("${path.module}/templates/kubernetes/kafka/kafka-pv.yaml.tpl",  {
    namespace             = var.namespace
  })
  filename = "${path.module}/kubernetes/kafka/kafka-pv.yaml"
}

resource "local_file" "kafka_vs" {
  content = templatefile("${path.module}/templates/kubernetes/kafka/kafka-vs.yaml.tpl",  {
    domain                = var.context.domain
    namespace             = var.namespace
    service_name          = var.kafka.service_name
  })
  filename = "${path.module}/kubernetes/kafka/kafka-vs.yaml"
}


resource "local_file" "kafka_deploy" {
  content = templatefile("${path.module}/templates/kubernetes/kafka/kafka-deploy.yaml.tpl",  {
    domain                = var.context.domain
    namespace             = var.namespace
    nodeSelector          = var.node_name
    toolchain_repository  = local.toolchain_repository
    kafka_image           = var.kafka.image_name
    kafka_version         = var.kafka.image_version
    service_name          = var.kafka.service_name
    heap_opts             = var.kafka.heap_opts
    daemon_opts           = var.kafka.daemon_opts
  })
  filename = "${path.module}/kubernetes/kafka/kafka-deploy.yaml"
}


# deploy kafka
resource "null_resource" "deploy_kafka" {

  provisioner "local-exec" {
    command = <<EOT
      kubectl get gateway -n basic dxservice-gw -o json --context ${local.eks_context_name} \
      | jq '.spec.servers[0].hosts[.spec.servers[0].hosts| length] = "${format("kafka.%s", var.context.domain)}"' \
      | kubectl replace -f -
    EOT
    environment = {
      AWS_PROFILE = var.context.aws_profile
      AWS_REGION  = var.context.aws_region
      KUBECONFIG  = pathexpand("~/.kube/config")
    }
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/kubernetes/kafka/kafka-ns.yaml --context ${local.eks_context_name}"
    environment = {
      AWS_PROFILE = var.context.aws_profile
      AWS_REGION  = var.context.aws_region
      KUBECONFIG  = pathexpand("~/.kube/config")
    }
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/kubernetes/kafka/kafka-pv.yaml --context ${local.eks_context_name}"
    environment = {
      AWS_PROFILE = var.context.aws_profile
      AWS_REGION  = var.context.aws_region
      KUBECONFIG  = pathexpand("~/.kube/config")
    }
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/kubernetes/kafka/kafka-vs.yaml --context ${local.eks_context_name}"
    environment = {
      AWS_PROFILE = var.context.aws_profile
      AWS_REGION  = var.context.aws_region
      KUBECONFIG  = pathexpand("~/.kube/config")
    }
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/kubernetes/kafka/kafka-deploy.yaml --context ${local.eks_context_name}"
    environment = {
      AWS_PROFILE = var.context.aws_profile
      AWS_REGION  = var.context.aws_region
      KUBECONFIG  = pathexpand("~/.kube/config")
    }
  }

  depends_on = [
    null_resource.update_eks_kubeconfig,
    aws_eks_node_group.node,
    local_file.kafka_ns,
    local_file.kafka_ns,
    local_file.kafka_pv,
    local_file.kafka_vs,
    local_file.kafka_deploy
  ]

}