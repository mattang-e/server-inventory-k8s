# Server Inventory API

FastAPI 기반 Server Inventory API를 Kubernetes Deployment로 배포합니다.

Container image는 Private Harbor Registry에서 관리하며,
Kubernetes `imagePullSecret`을 사용하여 이미지를 Pull합니다.

## Resources

- `configmap.yaml` - Database connection configuration
- `deployment.yaml` - FastAPI Deployment
- `service.yaml` - FastAPI ClusterIP Service

## Container Image

    harbor.lab.local/server-inventory/server-inventory-api:v1

FastAPI Deployment는 2개의 replica로 구성합니다.

## Configuration

일반 DB 연결 정보는 `api-config` ConfigMap에서 관리합니다.

```text
    DB_HOST=postgres
    DB_NAME=app_db
```
DB 인증정보는 `postgres-secret` Secret을 참조합니다.
```text
    POSTGRES_USER -> DB_USER
    POSTGRES_PASSWORD -> DB_PASSWORD
```
## Harbor Authentication

Private Harbor Registry에서 이미지를 Pull하기 위해
`harbor-secret`을 생성합니다.
```shell
    kubectl create secret docker-registry harbor-secret \
      --docker-server=harbor.lab.local \
      --docker-username=<username> \
      --docker-password=<password> \
      -n server-inventory
```

## Deploy
```shell
    kubectl apply -f configmap.yaml
    kubectl apply -f deployment.yaml
    kubectl apply -f service.yaml
```
## Verify
```shell
    kubectl get deployment,pod,svc -n server-inventory
```