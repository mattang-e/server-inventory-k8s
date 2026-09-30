# Gateway API

Server Inventory API의 외부 HTTP 트래픽 처리를 위해
Kubernetes Gateway API와 Envoy Gateway를 사용합니다.

## Architecture
```text

    Client
      |
      | HTTP :80
      v
    MetalLB VIP
    192.168.10.116
      |
      v
    Envoy LoadBalancer Service
      |
      v
    Envoy Proxy
      |
      | HTTPRoute
      v
    server-inventory-api Service :8000
      |
      v
    FastAPI Pods
```

## Envoy Gateway

Gateway API 구현체로 Envoy Gateway를 사용합니다.

Helm을 사용하여 Envoy Gateway Controller와
Gateway API 관련 CRD를 설치합니다.
```shell
    helm install eg \
      oci://docker.io/envoyproxy/gateway-helm \
      --version v1.9.1 \
      -n envoy-gateway-system \
      --create-namespace
```
설치 상태를 확인합니다.
```shell
    kubectl get pods -n envoy-gateway-system
```
## Resources

- `gatewayclass.yaml` - Envoy Gateway Controller를 사용하는 GatewayClass
- `gateway.yaml` - HTTP 80 포트를 사용하는 Gateway
- `httproute.yaml` - FastAPI Service로 요청을 전달하는 HTTPRoute

## GatewayClass

`envoy` GatewayClass는 Envoy Gateway Controller와 연결됩니다.

    controllerName: gateway.envoyproxy.io/gatewayclass-controller

## Gateway

`server-inventory-gateway`는 HTTP 80 포트에서 요청을 수신합니다.

같은 `server-inventory` Namespace의 HTTPRoute만
Gateway에 연결할 수 있도록 구성합니다.

## HTTPRoute

`server-inventory-route`는 Gateway로 들어온 HTTP 요청을
FastAPI Service로 전달합니다.
```text
    server-inventory-api:8000
```
별도의 path match를 지정하지 않았으므로 `/`를 기준으로
API 경로가 전달됩니다.

예:

    /servers
    /servers/1
    /docs

## Deploy
```shell
    kubectl apply -f gatewayclass.yaml
    kubectl apply -f gateway.yaml
    kubectl apply -f httproute.yaml
```
## Verify

GatewayClass를 확인합니다.

    kubectl get gatewayclass

Gateway와 HTTPRoute 상태를 확인합니다.
```shell
    kubectl get gateway,httproute -n server-inventory
```
HTTPRoute 상세 상태를 확인합니다.
```shell
    kubectl describe httproute server-inventory-route \
      -n server-inventory
```
정상적으로 연결되면 HTTPRoute에서 다음 상태를 확인할 수 있습니다.

    Accepted=True
    ResolvedRefs=True