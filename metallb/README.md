# MetalLB

On-Premise Kubernetes 환경에서 `LoadBalancer` 타입의 Service에
외부 접근 가능한 IP를 제공하기 위해 MetalLB를 사용합니다.

현재 환경에서는 L2 mode를 사용하며,
Server Inventory API의 외부 VIP로 `192.168.10.116`을 사용합니다.

## Architecture
```text
    Client
      |
      | HTTP
      v
    192.168.10.116
    MetalLB VIP
      |
      v
    Envoy LoadBalancer Service
      |
      v
    Envoy Proxy
      |
      | HTTPRoute
      v
    server-inventory-api Service
      |
      v
    FastAPI Pods
```
## Install

Helm Repository를 추가합니다.
```shell
    helm repo add metallb https://metallb.github.io/metallb
    helm repo update
```
MetalLB를 설치합니다.
```shell
    helm install metallb metallb/metallb \
      -n metallb-system \
      --create-namespace
```
설치 상태를 확인합니다.
```shell
    kubectl get pods -n metallb-system
```
## IPAddressPool

`IPAddressPool`은 LoadBalancer Service에 할당할 수 있는
IP 주소 범위를 정의합니다.

현재 Lab에서는 하나의 VIP를 사용합니다.

    192.168.10.116/32

`/32`이므로 단일 IP 주소만 Pool에 포함됩니다.

## L2Advertisement

`L2Advertisement`는 MetalLB가 IPAddressPool의 VIP를
L2 네트워크에 광고할 수 있도록 설정합니다.

L2 mode에서는 MetalLB Speaker가 ARP/NDP를 이용하여
VIP에 대한 네트워크 도달성을 제공합니다.

## Resources

- `metallb-config.yaml` - IPAddressPool 및 L2Advertisement

## Deploy

MetalLB가 먼저 설치되어 있어야 합니다.
```shell
    kubectl apply -f metallb-config.yaml
```
## Verify

MetalLB 리소스를 확인합니다.
```shell
    kubectl get ipaddresspool -n metallb-system
    kubectl get l2advertisement -n metallb-system
```
LoadBalancer Service의 External IP를 확인합니다.
```shell
    kubectl get svc -A | grep LoadBalancer
```
정상적으로 구성되면 Envoy LoadBalancer Service에
`192.168.10.116` External IP가 할당됩니다.

## Test

Kubernetes Cluster 외부의 동일 네트워크 클라이언트에서
Server Inventory API에 접근합니다.

    curl http://192.168.10.116/servers