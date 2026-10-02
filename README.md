# Server Inventory Kubernetes

FastAPI 기반 Server Inventory API를 On-Premise Kubernetes 환경에
배포하고 운영하기 위한 Kubernetes 인프라 구성입니다.

Private Harbor Registry를 통해 Container Image를 관리하며,
Gateway API와 Envoy Gateway를 이용하여 HTTP 트래픽을 처리합니다.

On-Premise 환경에서 `LoadBalancer` Service를 사용하기 위해
MetalLB를 구성했으며, PostgreSQL 데이터는 NetApp NFS Storage에
영구 저장합니다.

## Architecture
```text
    Client
      |
      | HTTP
      v
    MetalLB
    VIP: 192.168.10.116
      |
      v
    Envoy LoadBalancer Service
      |
      v
    Envoy Proxy
      |
      | Gateway API
      | Gateway / HTTPRoute
      v
    server-inventory-api Service
      |
      +-------------------+
      |                   |
      v                   v
    FastAPI             FastAPI
    Pod                 Pod
      |                   |
      +---------+---------+
                |
                | DB_HOST=postgres
                v
         PostgreSQL Service
                |
                v
           PostgreSQL
           StatefulSet
                |
                v
               PVC
                |
                v
        NetApp NFS Storage


    Container Image Deployment

    Application Source
       |
       v
    Jenkins
       |
       | Podman Build / Push
       v
Private Harbor Registry
       |
       | Image Pull
       v
Kubernetes FastAPI Pods
```
## Tech Stack

- Kubernetes 1.34
- Containerd
- Calico
- Gateway API
- Envoy Gateway
- MetalLB
- Harbor
- FastAPI
- PostgreSQL 17
- NetApp NFS
- Helm

## Repository Structure

    server-inventory-k8s/
    ├── namespace/
    │   └── namespace.yaml
    │
    ├── api/
    │   ├── README.md
    │   ├── configmap.yaml
    │   ├── deployment.yaml
    │   └── service.yaml
    │
    ├── postgres/
    │   ├── README.md
    │   ├── init.sql
    │   ├── configmap.yaml
    │   ├── secret.example.yaml
    │   ├── postgres-pv.yaml
    │   ├── statefulset.yaml
    │   └── service.yaml
    │
    ├── gateway/
    │   ├── README.md
    │   ├── gatewayclass.yaml
    │   ├── gateway.yaml
    │   └── httproute.yaml
    │
    ├── metallb/
    │   ├── README.md
    │   └── metallb-config.yaml
    │
    └── docs/
        └── troubleshooting.md

## Related Repositories

### Application

[server-inventory-api](https://github.com/mattang-e/server-inventory-api)

FastAPI와 PostgreSQL을 사용하는 Server Inventory REST API의
Application Source 및 Docker Image Build 구성을 관리합니다.

### Kubernetes Platform

[kubernetes-platform-lab](https://github.com/mattang-e/kubernetes-platform-lab)

Kubernetes HA Cluster, Containerd, Calico 및
On-Premise Kubernetes Platform 구축 구성을 관리합니다.

### Kubernetes Deployment

현재 Repository인 [server-inventory-k8s](https://github.com/mattang-e/server-inventory-k8s) 는
Server Inventory API를 Kubernetes 환경에 배포하고 운영하기 위한
Application Infrastructure 구성을 관리합니다.
