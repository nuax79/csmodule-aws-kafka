---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: kafka-vs
  namespace: ${namespace}
spec:
  hosts:
  - "kafka.${domain}"
  gateways:
  - basic/dxservice-gw
  http:
  - headers:
      request:
        set:
          x-forwarded-port: "443"
          x-forwarded-proto: https
    match:
    - uri:
        prefix: /
    route:
    - destination:
        port:
          number: 9092
        host: ${service_name}

---
apiVersion: v1
kind: Service
metadata:
  name: ${service_name}
  labels:
    app: kafka
  namespace: ${namespace}
spec:
  type: ClusterIP
  ports:
    - name: broker
      protocol: TCP
      port: 9092
      targetPort: 9092
  selector:
    app: kafka