# PostgreSQL

Server Inventory API에서 사용하는 PostgreSQL 데이터베이스입니다.

PostgreSQL은 StatefulSet으로 배포하며, 데이터 영속성을 위해
NetApp NFS 기반 PersistentVolume을 사용합니다.

## Resources

- `secret.example.yaml` - PostgreSQL 인증정보 템플릿
- `configmap.yaml` - 데이터베이스 초기화 SQL
- `pv.yaml` - NetApp NFS PersistentVolume
- `statefulset.yaml` - PostgreSQL StatefulSet
- `service.yaml` - PostgreSQL ClusterIP Service

## Architecture
```text
    FastAPI
       |
       | postgres:5432
       v
    PostgreSQL Service
       |
       v
    PostgreSQL StatefulSet
       |
       v
    PVC
       |
       v
    PersistentVolume
       |
       v
    NetApp NFS
```
## Secret

실제 데이터베이스 인증정보는 Git에 저장하지 않습니다.

예제 파일을 복사하여 Secret을 생성합니다.

    cp secret.example.yaml secret.yaml

`secret.yaml`에 실제 인증정보를 설정한 후 Kubernetes에 적용합니다.

    kubectl apply -f secret.yaml

`secret.yaml`은 `.gitignore`에 의해 Git 관리에서 제외됩니다.

## Database Initialization

PostgreSQL 초기 스키마 및 테스트 데이터는 `init.sql`에서 관리합니다.

`init.sql`을 Kubernetes ConfigMap으로 생성합니다.
```shell
    kubectl create configmap postgres-init \
      --from-file=init.sql=init.sql \
      -n server-inventory \
      --dry-run=client \
      -o yaml | kubectl apply -f -
```
생성된 ConfigMap은 PostgreSQL StatefulSet에서
`/docker-entrypoint-initdb.d/init.sql`로 마운트됩니다.

PostgreSQL 데이터 디렉터리가 처음 초기화될 때 해당 SQL이 실행됩니다.

## Deploy
```shell
    kubectl apply -f configmap.yaml
    kubectl apply -f pv.yaml
    kubectl apply -f statefulset.yaml
    kubectl apply -f service.yaml
```
## Verify
```shell
    kubectl get sts,pod,svc,pvc -n server-inventory
    kubectl get pv postgres-pv
```