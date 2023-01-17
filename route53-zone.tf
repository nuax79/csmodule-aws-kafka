# Public DNS Record for Ingress ALB Controller
locals {
  ingress_alb_name  = data.aws_alb.this.dns_name
}

# Public Host Zone
data "aws_route53_zone" "public" {
  name = var.context.domain
}

resource "aws_route53_record" "kafka_public" {
  zone_id = data.aws_route53_zone.public.id
  name    = format("kafka.%s", var.context.domain)
  type    = "CNAME"
  ttl     = "300"
  records = [local.ingress_alb_name]
  allow_overwrite = true
}
