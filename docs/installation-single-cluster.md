# Single Cluster
하나의 호스트 컴퓨텅에 Kafka 클러스터를 멀티 노드로 구성합니다.


## Prerequisite
kafka 는 Java 런타임이 필요하며 java 11 과 java 8 버전을 지원하고 있습니다. java 11 버전이 훨씬 더 좋은 성능을 발휘 합니다. 
```
sudo add-apt-repository ppa:openjdk-r/ppa
sudo apt install openjdk-11-jdk
```

## Download kafka

- Download kafka 2.8.0 from https://kafka.apache.org/downloads
```
cd /tmp
wget https://dlcdn.apache.org/kafka/2.8.0/kafka_2.13-2.8.0.tgz
```

- Extract kafka
```
tar xvzf kafka_2.13-2.8.0.tgz
```

## Kafka cluster configuration
kafka 는 홀수의 노드로 클러스터를 구성하며 3개의 노드를 기준으로 구성을 진행 합니다.  

### server.properties
KAFKA_HOME/config/kraft/server.properties 설정 파일을 3개로 나누어 구성 합니다.
```
cd kafka_2.13-2.8.0
cd config/kraft
cp server.properties server1.properties
cp server.properties server2.properties
cp server.properties server3.properties
```

server1.properties 을 기준으로 편집할 주요 속성은 다음과 같습니다.
```shell
node.id=1
process.roles=broker,controller
inter.broker.listener.name=PLAINTEXT
controller.listener.names=CONTROLLER
listeners=PLAINTEXT://:9092,CONTROLLER://:19092
log.dirs=/tmp/server1/kraft-combined-logs
controller.quorum.voters=1@localhost:19092,2@localhost:19093,3@localhost:19094
listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL
```

| Property name                 | Description   |
| :---:                         | :---          |
| node.id                       | 클러스터가 노드 역할을 식별하는데 사용 됩니다. (server1 이) 어떤 브로커인지 또는 어떤 크래프트 컨트롤러 노드인지 식별합니다. |
| process.roles                 | 노드는 브로커나 컨트롤러 또는 둘 다의 역할을 할 수 있습니다.       |
| inter.broker.listener.name    | 브로커가 내부 네트워크 통신을 위해사용되는 리스너 이름 입니다.     |
| controller.listener.names     | 컨트롤러가 내부 네트워크 통신을 위해사용되는 리스너 이름 입니다.   |
| listeners                     | (server1 의) 브로커와 컨트롤러의 Listen 포트를 정의 합니다.        |
| log.dirs                      | (server1 의) kafka 가 데이터를 저장할 로그 디렉토리입니다.         |
| controller.quorum.voters      | 사용 가능한 모든 크래프트 컨트롤러 노드를 정의 합니다.             |
| listener.security.protocol.map| 클러스터 내의 노드간 통신을 위한 프로토콜을 정의 합니다.           |

server2.properties, server3.properties 파일 역시 노드에 맞게 주요 속성을 편집 합니다.

### Kafka cluster id creation and log directory setup
- Kafka 클러스터 uuid 를 생성 합니다.
```shell
./bin/kafka-storage.sh random-uuid
```
- Kafka 클러스터 uuid 를 적용하여 server1 노드의 로그 디렉토리를 설정 합니다.
```shell
./bin/kafka-storage.sh format -t <KAFKA_UUID> -c ./config/kraft/server1.properties

# server2 의 경우
./bin/kafka-storage.sh format -t <KAFKA_UUID> -c ./config/kraft/server2.properties

# server3 의 경우
./bin/kafka-storage.sh format -t <KAFKA_UUID> -c ./config/kraft/server3.properties
```

## Starting the kafka servers
컨트롤러 리스너를 tcp4 프로토콜로 동작하기 위해 KAFKA_OPTS 환경변수를 설정 합니다.  
JVM 힙 메모리 크기를 정의 합니다. Host 컴퓨터의 Memory 를 고려하여 설정 합니다. 
```
export KAFKA_OPTS="-Djava.net.preferIPv4Stack=True"
export KAFKA_HEAP_OPTS="-Xmx2G -Xms1G"
```

- Start Server:
```shell
./bin/kafka-server-start.sh -daemon ./config/kraft/server1.properties
./bin/kafka-server-start.sh -daemon ./config/kraft/server2.properties
./bin/kafka-server-start.sh -daemon ./config/kraft/server2.properties
```

## Create a kafka topic
- Kafka 클러스터에 kraft topic 을 테스트로 생성 합니다.
```shell
./bin/kafka-topics.sh --create --topic kraft-test --partitions 3 --replication-factor 3 --bootstrap-server localhost:9092
```

- 다른 Kafka 컨트롤러를 통해 kraft-test 토픽을 describe 으로 확인 합니다.
```shell
./bin/kafka-topics.sh --bootstrap-server localhost:9093 --describe --topic kraft-test
```
- 다음과 유사한 결과가 출력 됩니다.
```shell
Topic: kraft-test	TopicId: 6T5UBWgdR1uUrUFWD0yWMA	PartitionCount: 3	ReplicationFactor: 3	Configs: segment.bytes=1073741824
	Topic: kraft-test	Partition: 0	Leader: 3	Replicas: 3,2,1	Isr: 3,2,1
	Topic: kraft-test	Partition: 1	Leader: 2	Replicas: 2,1,3	Isr: 2,1,3
	Topic: kraft-test	Partition: 2	Leader: 2	Replicas: 2,1,3	Isr: 2,1,3
```

## Exploring the kafka metadata using metadata shell
Kafka 2.8.0 버전부터 새롭게 추가된 @metadata 토픽 관리는 KRaft Quorum 컨트롤러 노드로 대체 되었습니다. (기존은 Zookeeper)  
- Zookeeper cli와 유사하게 @metadata 내부 토픽의 데이터를 읽을 수 있도록 kafk a에서 제공하는 메타데이터 쉘을 이용하여 확인 합니다.
```shell
./bin/kafka-metadata-shell.sh  --snapshot /tmp/server1/kraft-combined-logs/@metadata-0/00000000000000000000.log
```
- 메타데이터 콘솔로 진입 하여 brokers / topics / topic 데이터 등을 확인할 수 있습니다. (Zookeeper CLI 와 상당히 유사함)
```shell
Loading...
Starting...
[ Kafka Metadata Shell ]
# 브로커 확인 
>> ls brokers/
1  2  3
>>
# 토픽 확인 
>> ls topics
kraft-test
>>
# topic metadata 학인 
>> cat topics/kraft-test/0/data
{
  "partitionId" : 0,
  "topicId" : "6T5UBWgdR1uUrUFWD0yWMA",
  "replicas" : [ 3, 2, 1 ],
  "isr" : [ 3, 2, 1 ],
  "removingReplicas" : null,
  "addingReplicas" : null,
  "leader" : 3,
  "leaderEpoch" : 0,
  "partitionEpoch" : 0
}
>>
# 컨트롤러 리더 노드 확인
>> cat metadataQuorum/leader
MetaLogLeader(nodeId=1, epoch=72)
>>
# exit 명령은 콘솔을 빠져나옵니다.
>> exit
```

## Producing and consuming data from kafka
kafka 클러스터에 데이터를 생성하고 소비하는것을 확인 할 수 있습니다.  
두개의 터미널에 kafka-console-producer.sh 생산자와, kafka-console-consumer.sh 소비자 콘솔을 엽니다.
- 먼저 생산자 kraft-test 토픽 콘솔에 진입 합니다.
```shell
./bin/kafka-console-producer.sh --broker-list localhost:9092 --topic kraft-test
```
- 다음으로, 소비자 kraft-test 토픽 콘솔에 진입 합니다.
```shell
./bin/kafka-console-consumer.sh --broker-list localhost:9094 --topic kraft-test
```

- 생산자 콘솔에서 다음 메시지를 입력하면 해당 메시지가 소비자 콘솔에서 소비되는것을 확인 할 수 있습니다.
```shell
# 생산자 콘솔에서 입력한 내용
./bin/kafka-console-producer.sh --broker-list localhost:9092 --topic kraft-test
>message 1
>message 2
>message 3
>Hello World!
>Bye
>
```

```shell
# 소비자 콘솔에서 출력한 내용
./bin/kafka-console-consumer.sh --bootstrap-server localhost:9094 --topic kraft-test
message 1
message 2
message 3
Hello World!
Bye
```

Ctrl + C 를 입력하여 빠져 나옵니다.

## Stopping the kafka servers
kafka-server-stop.sh 쉘을 통해 모든 노드가 한번에 내려 갑니다.
```
./bin/kafka-server-stop.sh
```