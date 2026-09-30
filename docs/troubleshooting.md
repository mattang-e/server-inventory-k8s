# Troubleshooting

Server Inventory API를 On-Premise Kubernetes 환경에 배포하면서
발생한 주요 문제와 해결 과정을 정리합니다.

---

## 1. Harbor Private CA Trust

### Problem

Private CA를 사용하는 Harbor Registry에 Docker 및 containerd에서
접근할 때 TLS 인증서 신뢰 문제가 발생했습니다.

### Cause

Harbor는 Private CA로 발급한 HTTPS 인증서를 사용하지만,
Docker Client와 Kubernetes Worker의 containerd는 기본적으로
해당 CA를 신뢰하지 않습니다.

### Solution

Docker Client에 Harbor CA를 등록했습니다.

    ~/.docker/certs.d/harbor.lab.local/ca.crt

Kubernetes Worker에는 다음 경로로 CA와 Registry 설정을 구성했습니다.

    /etc/containerd/certs.d/harbor.lab.local/ca.crt
    /etc/containerd/certs.d/harbor.lab.local/hosts.toml

containerd 설정에서 Registry configuration path를 지정했습니다.

    config_path = "/etc/containerd/certs.d"

설정 후 containerd를 재시작했습니다.

    systemctl restart containerd

### Result

Kubernetes Worker의 containerd에서 Private Harbor Image를
정상적으로 Pull할 수 있었습니다.

---

## 2. Container Image Architecture Mismatch

### Problem

Harbor에 Push한 FastAPI Image를 Kubernetes에서 실행할 때
Container가 정상적으로 실행되지 않았습니다.

### Environment

Image Build:

    Apple Silicon Mac

Kubernetes Worker:

    linux/amd64

### Cause

Apple Silicon 환경에서 기본 설정으로 Image를 빌드하면서
Kubernetes Worker와 Container Image Architecture가 일치하지 않았습니다.

### Solution

Docker Buildx를 사용하여 Target Platform을 명시했습니다.

    docker buildx build \
      --platform linux/amd64 \
      -t harbor.lab.local/server-inventory/server-inventory-api:v1 \
      --push .

### Result

Kubernetes Worker에서 FastAPI Container가 정상적으로 실행되었습니다.

---

## 3. Private Harbor Image Pull Authentication

### Problem

Harbor Project가 Private이므로 Kubernetes가 인증정보 없이
Container Image를 Pull할 수 없습니다.

### Solution

`server-inventory` Namespace에 Registry Secret을 생성했습니다.

    kubectl create secret docker-registry harbor-secret \
      --docker-server=harbor.lab.local \
      --docker-username=<username> \
      --docker-password=<password> \
      -n server-inventory

FastAPI Deployment에서 Secret을 참조했습니다.

    spec:
      imagePullSecrets:
        - name: harbor-secret

### Result

Kubernetes에서 Private Harbor Image를 정상적으로 Pull했습니다.

---

## 4. NetApp NFS PersistentVolume Mount

### Problem

PostgreSQL 데이터를 외부 NetApp NFS Storage에 저장하기 위해
Static PersistentVolume을 구성해야 했습니다.

### Check

Worker Node에서 NFS 접근 가능 여부를 먼저 확인했습니다.

NFS Client Package가 필요하므로 Worker에 `nfs-utils`를 설치하고
수동 NFS Mount를 통해 연결 상태를 검증했습니다.

### Solution

NetApp NFS Export를 사용하는 Static PersistentVolume을 생성하고,
PostgreSQL StatefulSet의 `volumeClaimTemplates`에서 PVC를 생성하도록
구성했습니다.

    PostgreSQL
         |
         v
        PVC
         |
         v
    Static PV
         |
         v
    NetApp NFS

`storageClassName: ""`을 사용하여 Dynamic Provisioning이 아닌
Static PV를 사용하도록 구성했습니다.

### Result

PostgreSQL PVC가 `postgres-pv`와 Bound 되었고,
PostgreSQL 데이터를 NFS Storage에 영구 저장할 수 있었습니다.

---

## 5. PostgreSQL Initialization

### Problem

PostgreSQL Container를 재시작해도 `init.sql`이 매번 다시
실행되는 것이 아니라는 점을 확인할 필요가 있었습니다.

### Cause

PostgreSQL 공식 Container Image의
`/docker-entrypoint-initdb.d/` 초기화 Script는
Database Data Directory가 비어 있는 최초 초기화 시 실행됩니다.

### Configuration

`postgres-init` ConfigMap을 다음 경로에 Mount했습니다.

    /docker-entrypoint-initdb.d/init.sql

### Result

최초 Database 생성 시 Table과 초기 데이터가 생성되고,
기존 PersistentVolume의 데이터가 존재하는 경우 Pod 재시작 시
초기화 SQL이 반복 실행되지 않습니다.

---

## 6. Envoy NodePort Access with externalTrafficPolicy Local

### Problem

Envoy LoadBalancer Service의 NodePort를 테스트했을 때
일부 Worker Node에서는 접근할 수 없고 Envoy Proxy가 실행 중인
Worker에서만 접근할 수 있었습니다.

Envoy Proxy는 당시 `worker03`에서 실행 중이었습니다.

### Investigation

Envoy LoadBalancer Service 설정을 확인한 결과:

    externalTrafficPolicy: Local
    internalTrafficPolicy: Cluster

Envoy Proxy Endpoint는 `worker03`에 존재했습니다.

### Cause

`externalTrafficPolicy: Local`에서는 외부에서 NodePort로 들어온
트래픽을 해당 Node의 Local Endpoint로만 전달합니다.

따라서:

    worker01 -> Local Envoy Endpoint 없음
    worker02 -> Local Envoy Endpoint 없음
    worker03 -> Local Envoy Endpoint 있음

구조였기 때문에 `worker03`을 통한 접근만 정상 동작했습니다.

### Traffic Flow

    Client
      |
      v
    worker03 NodePort
      |
      | externalTrafficPolicy: Local
      v
    Envoy Proxy
      |
      v
    FastAPI Service

### Result

NodePort와 `externalTrafficPolicy: Local`의 관계를 확인했으며,
최종 외부 접근은 MetalLB VIP를 통해 구성했습니다.

---

## 7. MetalLB LoadBalancer VIP

### Problem

On-Premise Kubernetes 환경에는 Cloud Provider가 없기 때문에
`LoadBalancer` Service를 생성해도 외부 IP를 자동으로 제공할
Cloud Load Balancer가 존재하지 않습니다.

### Solution

MetalLB를 L2 Mode로 구성했습니다.

IPAddressPool:

    192.168.10.116/32

L2Advertisement를 구성하여 MetalLB Speaker가
VIP에 대한 L2 도달성을 제공하도록 설정했습니다.

### Traffic Flow

    Client
      |
      | ARP
      v
    MetalLB Speaker
      |
      | VIP 192.168.10.116
      v
    Envoy LoadBalancer Service
      |
      v
    Envoy Proxy
      |
      | HTTPRoute
      v
    FastAPI Service

### Result

Cluster 외부 Client에서 다음 주소를 통해 API에 접근할 수 있었습니다.

    http://192.168.10.116/servers