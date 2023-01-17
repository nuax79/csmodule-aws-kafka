context = {
    aws_credentials_file    = "$HOME/.aws/credentials"
    aws_profile             = "dxterra"
    aws_region              = "ap-northeast-2"
    region_alias            = "an2"

    project                 = "mercury"
    environment             = "prd"
    env_alias               = "p"
    owner                   = "dx@bespinglobal.com"
    team_name               = "Devops Transformation"
    team                    = "DX"
    domain                  = "test.co.kr"
}

namespace                   = "kafka"
ami_name                    = "dxkafka-node-ubuntu-18.04"
instance_type               = "m5.large"
node_name                   = "kafka"
asg_desired_capacity        = 1
asg_min_capacity            = 1
asg_max_capacity            = 2
docker_images               = []

# kafka
kafka = {
    image_name    = "kafka-kraft"
    image_version = "3.0.0"
    replicas      = "3"
    service_name  = "kafka-service"
    heap_opts     = "-Xmx1G -Xms1G"
    daemon_opts   = "-Djava.net.preferIPv4Stack=True"
}
