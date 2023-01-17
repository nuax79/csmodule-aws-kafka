# csmodule-aws-kafka

EKS 서비스 플랫폼에 kafka cluster 를 위한 EKS 워커 노드를 자동 구성하고 Kafka 클러스터를 PaaS 서비스로 구성 합니다.


## Prerequisite
kafka 클러스터 서비스를 자동 구성하기 위해 다음의 제약사항을 준수 하여야 합니다.

- EKS 클러스터가 사전에 구성되어 있어야 합니다.
- WorkerNode 를 생성 또는 기존의 구성 변경을 위한 credentials 이 제공 되어야 합니다. (AccessKey) 
- kafka 클러스터 구성을 위한 Worker 노드용 AMI 이미지가 사전 준비 되어 있어야 합니다. (dxkafka 접두어로 시작하는 AMI 이미지 이름 입니다.)
  참고로, terraform [context 정보](./terraform.tfvars)를 기준으로 다음의 AWS 리소스를 데이터소스로 참조 합니다.
```hcl
context = {
  ...
  project       = "mercury"
  region_alias  = "an2"
  env_alias     = "p"
  ...
}
```
위와 같은 context 정보를 구성 하는경우 참조 데이터 소스는 다음과 같습니다.

| Resource      | Name                      | Description   |
| :---          | :---                      | :---          |
| VPC           | mercury-an2p-vpc          | aws_vpc 데이터 소스 참조 이름  |
| EKS Cluster   | mercury-an2p-eks          | aws_eks_cluster EKS 데이터 소스 참조 이름  |
| IAM Role      | mercuryEksWorkerEC2Role   | EKS WorkerNode 가 사용하는 aws_iam_role 데이터 소스 참조 이름  |
| SecurityGroup | mercury-an2p-worker-sg    | EKS WorkerNode 가 사용하는 aws_security_group 데이터 소스 참조 이름  |
- 현재 운영 중인 서비스 플랫폼의 구성 정보를 확인 하여 [terraform.tfvars](./terraform.tfvars) 를 구성 합니다.
```shell
# aws eks describe-cluster --name <cluster_name>
aws eks describe-cluster --name mercury-an2p-eks --output=json
```

### AWS Configure Profile
'dxterra' 프로파일을 구성하는 예시 입니다.

```shell
aws configure --profile dxterra

AWS Access Key ID [None]: *********
AWS Secret Access Key [None]: *******
Default region name [None]: ap-northeast-2
Default output format [None]: json

export AWS_DEFAULT_PROFILE=dxterra
export AWS_PROFILE=dxterra
export AWS_REGION=ap-northeast-2
```

## Variables
kafka 클러스터 구성에 필요한 변수를 설정 합니다.
[terraform.tfvars](./terraform.tfvars)


## Build
서비스 플랫폼 환경의 EKS 클러스터에 새로운 워커 노드 (예: mercury-kafka)를 추가 합니다.

```shell
# git 인증 규칙 설정
git config --global credential.helper store

git clone https://github.com/bsp-dx/csmodule-aws-kafka.git mercury-kafka
cd mercury-kafka

terraform init
terraform plan
terraform apply
```

## Checking
kubectl 명령을 통해 EKS 클러스터에 새롭게 추가된 kafka node group 을 확인할 수 있습니다.

```shell
# aws eks update-kubeconfig --name  <eks_cluster_name>
aws eks update-kubeconfig --name mercury-an2p-eks

# kubectl get node --show-labels | grep <node_name>
kubectl get node --show-labels | grep kafka

# kafka 관련 kubernetes 리소스 확인
kubectl -n kafka get po,svc,statefulset,pvc
```

## Appendix
- Topic 을 생성 하려면 kafka 컨테이너 내부에 접속 하여 아래 명령을 입력 합니다.
```shell
kubectl -n kafka exec -it kafka-0 -- /bin/bash

kafka-topics.sh --create --topic my-first-topic --partitions 3 --replication-factor 3 --bootstrap-server kafka-0:9092
```
- 생성된 Topic 을 확인 하려면 kafka 컨테이너 내부에 접속 하여 아래 명령을 입력 합니다.
```shell
kubectl -n kafka exec -it kafka-0 -- /bin/bash

kafka-topics.sh --describe --topic my-first-topic --bootstrap-server kafka-0:9092
```
 