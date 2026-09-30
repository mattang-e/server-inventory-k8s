# Harbor Private Registry

Server Inventory API의 Container Image를 관리하기 위해
On-Premise 환경에 Private Harbor Registry를 구성했습니다.

## Environment

- OS: Rocky Linux 8.10
- Harbor: v2.15.2
- Container Runtime: Docker Engine
- Deployment: Docker Compose
- Hostname: `harbor.lab.local`
- HTTPS: 443
- Harbor Data: `/data`

Harbor는 Kubernetes Cluster와 별도의 Registry Server에서 운영합니다.
```text
    Developer
        |
        | docker push
        v
    Harbor Private Registry
    harbor.lab.local
        |
        | image pull
        v
    Kubernetes Worker
        |
        | containerd
        v
    FastAPI Pod
```
## Harbor Installation

Harbor 설치 파일을 다운로드하고 압축을 해제합니다.

Harbor 설정 파일은 다음 경로에서 관리합니다.

    /opt/harbor/harbor.yml

주요 설정:

    hostname: harbor.lab.local

    https:
      port: 443
      certificate: /data/cert/harbor.crt
      private_key: /data/cert/harbor.key

    data_volume: /data

설정 완료 후 Harbor를 설치합니다.

    ./install.sh

Harbor Container 상태를 확인합니다.
```shell
    docker compose ps
```
## DNS

Harbor Registry는 다음 이름을 사용합니다.

    harbor.lab.local

Harbor를 사용하는 Client와 Kubernetes Worker에서
해당 이름을 Registry Server IP로 해석할 수 있어야 합니다.

## Private CA

Harbor는 HTTPS 통신을 사용하며 Private CA 인증서를 사용합니다.

Private CA를 사용하는 경우 Harbor에 접근하는 Client와
Kubernetes Worker가 해당 CA를 신뢰하도록 구성해야 합니다.

### Docker Client

Docker Client에서 Harbor CA를 신뢰하도록 설정합니다.

    ~/.docker/certs.d/harbor.lab.local/ca.crt

설정 후 Harbor에 로그인합니다.

    docker login harbor.lab.local

## Kubernetes Worker / containerd

Kubernetes Worker의 containerd에서도 Harbor Private CA를
신뢰하도록 설정합니다.

CA 인증서:

    /etc/containerd/certs.d/harbor.lab.local/ca.crt

Registry 설정:

    /etc/containerd/certs.d/harbor.lab.local/hosts.toml

예:

    server = "https://harbor.lab.local"

    [host."https://harbor.lab.local"]
      capabilities = ["pull", "resolve"]
      ca = "/etc/containerd/certs.d/harbor.lab.local/ca.crt"

containerd가 Registry별 설정을 읽을 수 있도록
`config.toml`에서 다음 경로를 사용합니다.

    config_path = "/etc/containerd/certs.d"

설정 변경 후 containerd를 재시작합니다.

    systemctl restart containerd

## Harbor Project

Server Inventory API Image는 다음 Project에서 관리합니다.

    server-inventory

Container Image:

    harbor.lab.local/server-inventory/server-inventory-api:v1

## Build and Push

Application Image를 빌드합니다.

Kubernetes Worker가 `linux/amd64` 환경이므로
빌드 Architecture를 명시합니다.
```shell
    docker buildx build \
      --platform linux/amd64 \
      -t harbor.lab.local/server-inventory/server-inventory-api:v1 \
      --push .
```
## Kubernetes Registry Secret

Harbor Project가 Private이므로 Kubernetes에서 Image를 Pull할 때
Registry 인증정보가 필요합니다.
```shell
    kubectl create secret docker-registry harbor-secret \
      --docker-server=harbor.lab.local \
      --docker-username=<username> \
      --docker-password=<password> \
      -n server-inventory
```
FastAPI Deployment에서 해당 Secret을 사용합니다.
```text
    spec:
      imagePullSecrets:
        - name: harbor-secret
```
실제 Harbor 인증정보는 Git Repository에 저장하지 않습니다.

## Image Pull Flow
```text
    FastAPI Deployment
            |
            | image
            | harbor.lab.local/...:v1
            v
         Kubelet
            |
            | harbor-secret
            v
    Harbor Private Registry
            |
            | HTTPS
            | Private CA Trust
            v
        containerd
            |
            v
       FastAPI Pod
```