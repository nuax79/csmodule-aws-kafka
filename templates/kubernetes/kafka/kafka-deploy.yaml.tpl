---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kafka
  labels:
    app: kafka
  namespace: ${namespace}
spec:
  serviceName: ${service_name}
  replicas: 3
  selector:
    matchLabels:
      app: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      nodeSelector:
        eks-nodegroup: ${nodeSelector}
      containers:
        - name: kafka
          image: "${toolchain_repository}/${kafka_image}:${kafka_version}"
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 9092
              protocol: TCP
            - containerPort: 9093
              protocol: TCP
          env:
            - name: REPLICAS
              value: "3"
            - name: SERVICE
              value: ${service_name}
            - name: NAMESPACE
              value: ${namespace}
            - name: SHARE_DIR
              value: "/mnt/kafka"
            - name: KAFKA_HEAP_OPTS
              value: "${heap_opts}"
            - name: KAFKA_OPTS
              value: "${daemon_opts}"
          volumeMounts:
            - name: kafka-storage
              mountPath: "/mnt/kafka"
      volumes:
        - name: kafka-storage
          persistentVolumeClaim:
            claimName: kafka-pvc