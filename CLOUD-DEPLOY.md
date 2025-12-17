# ☁️ Deploy em Cloud Providers

Guias para deploy do projeto containerizado em diferentes plataformas cloud.

## 🐳 Docker Hub / Registry

Primeiro, faça push das suas imagens para um registry:

```bash
# Login no Docker Hub
docker login

# Tag das imagens
docker tag my-store-backend seuusuario/medusa-backend:latest
docker tag my-store-storefront seuusuario/medusa-storefront:latest

# Push
docker push seuusuario/medusa-backend:latest
docker push seuusuario/medusa-storefront:latest
```

---

## 🚂 Railway

Railway já é suportado nativamente! Use o botão Deploy no README.

Para usar Docker:

1. Crie um novo projeto
2. Adicione PostgreSQL, Redis, MinIO, MeiliSearch
3. Deploy o backend e storefront como Docker containers

`railway.json`:
```json
{
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "backend/Dockerfile"
  },
  "deploy": {
    "startCommand": "pnpm start",
    "healthcheckPath": "/health",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

---

## 🎯 Digital Ocean

### App Platform

1. Conecte seu repositório GitHub
2. Configure como Docker Compose

`app.yaml`:
```yaml
name: medusa-store
services:
  - name: backend
    dockerfile_path: backend/Dockerfile
    source_dir: backend
    instance_count: 1
    instance_size_slug: professional-xs
    http_port: 9000
    health_check:
      http_path: /health
    envs:
      - key: DATABASE_URL
        scope: RUN_TIME
        value: ${db.DATABASE_URL}
      - key: REDIS_URL
        scope: RUN_TIME
        value: ${redis.REDIS_URL}

  - name: storefront
    dockerfile_path: storefront/Dockerfile
    source_dir: storefront
    instance_count: 1
    instance_size_slug: professional-xs
    http_port: 8000
    envs:
      - key: NEXT_PUBLIC_MEDUSA_BACKEND_URL
        scope: BUILD_AND_RUN_TIME
        value: https://backend-xxxxx.ondigitalocean.app

databases:
  - name: db
    engine: PG
    version: "16"
  - name: redis
    engine: REDIS
```

### Droplet (VPS)

```bash
# 1. Criar Droplet Ubuntu
# 2. Instalar Docker
ssh root@seu-ip
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 3. Clonar repositório
git clone https://github.com/seuusuario/my-store.git
cd my-store

# 4. Configurar
cp .env.example .env
nano .env

# 5. Iniciar
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## ☁️ AWS

### ECS (Elastic Container Service)

1. Push para ECR:
```bash
# Login ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com

# Tag e Push
docker tag my-store-backend:latest 123456789.dkr.ecr.us-east-1.amazonaws.com/medusa-backend:latest
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/medusa-backend:latest
```

2. Task Definition (`task-definition.json`):
```json
{
  "family": "medusa-backend",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "containerDefinitions": [
    {
      "name": "backend",
      "image": "123456789.dkr.ecr.us-east-1.amazonaws.com/medusa-backend:latest",
      "portMappings": [
        {
          "containerPort": 9000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        }
      ],
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789:secret:medusa/db-url"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/medusa-backend",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

### EC2

Similar ao Digital Ocean Droplet - veja seção acima.

### Elastic Beanstalk

`Dockerrun.aws.json`:
```json
{
  "AWSEBDockerrunVersion": 2,
  "containerDefinitions": [
    {
      "name": "backend",
      "image": "seuusuario/medusa-backend",
      "essential": true,
      "memory": 2048,
      "portMappings": [
        {
          "hostPort": 9000,
          "containerPort": 9000
        }
      ]
    }
  ]
}
```

---

## 🔵 Azure

### Container Instances

```bash
# Criar Resource Group
az group create --name medusa-rg --location eastus

# Deploy Container
az container create \
  --resource-group medusa-rg \
  --name medusa-backend \
  --image seuusuario/medusa-backend \
  --dns-name-label medusa-backend \
  --ports 9000 \
  --environment-variables \
    NODE_ENV=production \
  --secure-environment-variables \
    DATABASE_URL=$DATABASE_URL \
    JWT_SECRET=$JWT_SECRET
```

### App Service

```yaml
# azure-pipelines.yml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: Docker@2
  inputs:
    containerRegistry: 'dockerHub'
    repository: 'seuusuario/medusa-backend'
    command: 'buildAndPush'
    Dockerfile: 'backend/Dockerfile'

- task: AzureWebAppContainer@1
  inputs:
    appName: 'medusa-backend'
    imageName: 'seuusuario/medusa-backend:$(Build.BuildId)'
```

---

## 🌩️ Google Cloud

### Cloud Run

```bash
# Submit build
gcloud builds submit --tag gcr.io/seu-projeto/medusa-backend backend/

# Deploy
gcloud run deploy medusa-backend \
  --image gcr.io/seu-projeto/medusa-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 2Gi \
  --set-env-vars NODE_ENV=production \
  --set-secrets DATABASE_URL=medusa-db-url:latest
```

### GKE (Kubernetes)

Ver seção Kubernetes abaixo.

---

## ⎈ Kubernetes

### Deployment

`k8s/backend-deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: medusa-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: medusa-backend
  template:
    metadata:
      labels:
        app: medusa-backend
    spec:
      containers:
      - name: backend
        image: seuusuario/medusa-backend:latest
        ports:
        - containerPort: 9000
        env:
        - name: NODE_ENV
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: medusa-secrets
              key: database-url
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 9000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 9000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: medusa-backend
spec:
  selector:
    app: medusa-backend
  ports:
  - port: 9000
    targetPort: 9000
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: medusa-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - api.seudominio.com
    secretName: medusa-tls
  rules:
  - host: api.seudominio.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: medusa-backend
            port:
              number: 9000
```

`k8s/secrets.yaml`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: medusa-secrets
type: Opaque
stringData:
  database-url: "postgres://user:pass@postgres:5432/medusa"
  jwt-secret: "seu-jwt-secret"
  cookie-secret: "seu-cookie-secret"
```

Deploy:
```bash
kubectl apply -f k8s/
```

---

## 🟢 Heroku

`heroku.yml`:
```yaml
build:
  docker:
    backend: backend/Dockerfile
    storefront: storefront/Dockerfile
run:
  backend: pnpm start
  storefront: node server.js
```

```bash
# Login
heroku login
heroku container:login

# Criar app
heroku create medusa-backend

# Adicionar addons
heroku addons:create heroku-postgresql:essential-0
heroku addons:create heroku-redis:mini

# Deploy
heroku container:push backend -a medusa-backend
heroku container:release backend -a medusa-backend
```

---

## 🔶 Vercel (Apenas Storefront)

O backend precisa estar em outro lugar, mas o storefront pode ir para Vercel:

```json
// vercel.json
{
  "buildCommand": "cd storefront && pnpm build:next",
  "outputDirectory": "storefront/.next",
  "framework": "nextjs",
  "env": {
    "NEXT_PUBLIC_MEDUSA_BACKEND_URL": "https://api.seudominio.com",
    "NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY": "@medusa-publishable-key"
  }
}
```

---

## 🏠 Self-Hosted

### Docker Swarm

```bash
# Inicializar Swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml -c docker-compose.prod.yml medusa

# Ver serviços
docker service ls

# Scale
docker service scale medusa_backend=3
```

### Portainer

Interface gráfica para gerenciar Docker:

```bash
docker volume create portainer_data

docker run -d \
  -p 9443:9443 \
  --name=portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
```

Acesse: https://localhost:9443

---

## 📊 Comparação de Plataformas

| Plataforma | Facilidade | Custo | Escalabilidade | Controle |
|------------|-----------|-------|----------------|----------|
| Railway    | ⭐⭐⭐⭐⭐ | 💰💰 | ⭐⭐⭐ | ⭐⭐⭐ |
| Heroku     | ⭐⭐⭐⭐⭐ | 💰💰💰 | ⭐⭐⭐ | ⭐⭐ |
| Vercel     | ⭐⭐⭐⭐⭐ | 💰💰 | ⭐⭐⭐⭐ | ⭐⭐ |
| DO App Platform | ⭐⭐⭐⭐ | 💰💰 | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| DO Droplet | ⭐⭐⭐ | 💰 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| AWS ECS    | ⭐⭐ | 💰💰 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| AWS EC2    | ⭐⭐⭐ | 💰 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| GCP Cloud Run | ⭐⭐⭐⭐ | 💰💰 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Azure      | ⭐⭐⭐ | 💰💰 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Kubernetes | ⭐ | 💰-💰💰💰 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Self-Hosted | ⭐⭐ | 💰 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

## 🎯 Recomendações

### Para Começar (MVP)
- **Railway** ou **Heroku** - Setup rápido, zero configuração

### Pequeno a Médio Negócio
- **Digital Ocean App Platform** - Bom custo-benefício
- **Digital Ocean Droplet** - Mais controle, mesmo custo

### Escala Empresarial
- **AWS ECS/EKS** - Máxima flexibilidade
- **GCP Cloud Run** - Serverless, escala automática
- **Kubernetes** - Controle total, multi-cloud

### Baixo Orçamento
- **Self-Hosted VPS** (Hetzner, Vultr, Linode)
- **Digital Ocean Droplet**

## 🆘 Troubleshooting Comum

### Container não inicia
```bash
# Ver logs
docker logs <container-id>

# Comum: Variáveis de ambiente faltando
# Solução: Verificar .env ou secrets
```

### Conexão ao banco falha
```bash
# Testar conexão
docker exec -it backend sh
ping postgres

# Comum: Banco não está pronto
# Solução: Aguardar ou configurar depends_on com health check
```

### Build falha
```bash
# Limpar cache
docker builder prune -a

# Rebuild do zero
docker compose build --no-cache
```

---

**Dica:** Comece simples (Railway/Heroku) e migre conforme crescer!
