# 🚀 Otimizações e Boas Práticas para Produção

## 📦 Otimização de Imagens Docker

### 1. Multi-stage Builds
As imagens já utilizam multi-stage builds, mas você pode otimizar ainda mais:

```dockerfile
# Exemplo: adicionar cache de pnpm
RUN --mount=type=cache,id=pnpm,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile
```

### 2. Tamanho das Imagens
```bash
# Ver tamanho das imagens
docker images | grep medusa

# Analisar camadas
docker history my-store-backend

# Limpar cache após build
docker builder prune -f
```

## ⚡ Performance

### 1. Node.js em Produção

Adicione ao `docker-compose.prod.yml`:
```yaml
services:
  backend:
    environment:
      NODE_OPTIONS: "--max-old-space-size=2048"
```

### 2. PostgreSQL Tuning

Crie `postgres/postgresql.conf`:
```conf
# Memory
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
work_mem = 16MB

# Connections
max_connections = 100

# WAL
wal_buffers = 8MB
checkpoint_completion_target = 0.9
```

Adicione ao compose:
```yaml
postgres:
  volumes:
    - ./postgres/postgresql.conf:/etc/postgresql/postgresql.conf
  command: postgres -c config_file=/etc/postgresql/postgresql.conf
```

### 3. Redis Configuration

```yaml
redis:
  command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru
```

### 4. Next.js Optimization

Já configurado `output: 'standalone'`, mas adicione:

```javascript
// next.config.js
module.exports = {
  // ... existing config
  compress: true,
  poweredByHeader: false,
  generateEtags: true,
  
  // Image optimization
  images: {
    formats: ['image/avif', 'image/webp'],
    minimumCacheTTL: 60,
  },
}
```

## 🔒 Segurança

### 1. Secrets Management

Para produção, use Docker Secrets:

```yaml
# docker-compose.prod.yml
services:
  backend:
    secrets:
      - db_password
      - jwt_secret
    environment:
      DATABASE_URL: postgres://medusa:run/secrets/db_password@postgres:5432/medusa

secrets:
  db_password:
    file: ./secrets/db_password.txt
  jwt_secret:
    file: ./secrets/jwt_secret.txt
```

### 2. Network Security

```yaml
networks:
  medusa-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16
  
  # Rede interna apenas (sem acesso externo)
  medusa-internal:
    driver: bridge
    internal: true
```

### 3. Read-only Containers

```yaml
services:
  backend:
    read_only: true
    tmpfs:
      - /tmp
      - /app/.medusa/server
```

### 4. Non-root Users

Já implementado nos Dockerfiles! Todos os containers rodam com usuários não-privilegiados.

### 5. Security Scanning

```bash
# Escanear vulnerabilidades
docker scout cves my-store-backend
docker scout cves my-store-storefront

# Ou use Trivy
trivy image my-store-backend
```

## 📊 Monitoramento

### 1. Health Checks

Todos os serviços já possuem health checks configurados!

### 2. Logging

Configure log drivers:
```yaml
services:
  backend:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

Para produção, considere:
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Grafana Loki
- AWS CloudWatch
- Datadog

### 3. Metrics

Adicione Prometheus + Grafana:

```yaml
# docker-compose.monitoring.yml
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
  
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin

volumes:
  prometheus_data:
  grafana_data:
```

## 🔄 CI/CD

### GitHub Actions Example

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build images
        run: |
          docker compose build
      
      - name: Run tests
        run: |
          docker compose up -d postgres redis
          docker compose run backend pnpm test
      
      - name: Push to registry
        run: |
          echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
          docker compose push
      
      - name: Deploy
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.HOST }}
          username: ${{ secrets.USERNAME }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /app
            docker compose pull
            docker compose up -d
```

## 💾 Backup Automático

### Cron Job para Backup

```bash
# backup.sh
#!/bin/bash

BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d-%H%M%S)

# Backup PostgreSQL
docker compose exec -T postgres pg_dump -U medusa medusa | gzip > "$BACKUP_DIR/db-$DATE.sql.gz"

# Backup MinIO
docker compose exec -T minio mc mirror --quiet myminio/medusa-media "$BACKUP_DIR/minio-$DATE/"

# Remover backups antigos (mantém 7 dias)
find "$BACKUP_DIR" -type f -mtime +7 -delete

echo "Backup completo: $DATE"
```

Adicione ao crontab:
```bash
# Backup diário às 3h da manhã
0 3 * * * /app/backup.sh >> /var/log/medusa-backup.log 2>&1
```

## 🌐 CDN e Caching

### CloudFlare Setup

1. Configure DNS para apontar para seu servidor
2. Ative Cloudflare
3. Configure Page Rules:
   - `*.seudominio.com/_next/static/*` - Cache Everything
   - `*.seudominio.com/images/*` - Cache Everything

### Nginx Caching (alternativa)

```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=medusa:10m max_size=1g inactive=60m;

server {
    location /_next/static/ {
        proxy_cache medusa;
        proxy_cache_valid 200 60d;
        proxy_pass http://localhost:8000;
    }
}
```

## 🔧 Database Optimization

### Índices Recomendados

```sql
-- Conecte ao banco
docker compose exec postgres psql -U medusa medusa

-- Adicione índices para melhorar performance
CREATE INDEX idx_product_status ON product(status);
CREATE INDEX idx_order_created_at ON "order"(created_at);
CREATE INDEX idx_cart_updated_at ON cart(updated_at);

-- Analise performance
EXPLAIN ANALYZE SELECT * FROM product WHERE status = 'published';
```

### Vacuum Regular

```bash
# Adicione ao cron
0 2 * * 0 docker compose exec -T postgres psql -U medusa -c "VACUUM ANALYZE;" medusa
```

## 📱 Mobile Optimization

### Service Worker (PWA)

```javascript
// public/sw.js
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open('medusa-v1').then((cache) => {
      return cache.addAll([
        '/',
        '/offline',
        '/_next/static/css/*.css',
        '/_next/static/js/*.js',
      ]);
    })
  );
});
```

## 🎯 Load Balancing

Para escalar horizontalmente:

```yaml
# docker-compose.scale.yml
services:
  backend:
    deploy:
      replicas: 3
  
  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    ports:
      - "80:80"
    depends_on:
      - backend
```

```nginx
# nginx.conf
upstream backend {
    least_conn;
    server backend_1:9000;
    server backend_2:9000;
    server backend_3:9000;
}

server {
    location / {
        proxy_pass http://backend;
    }
}
```

## 📈 Checklist de Produção

- [ ] Alterar todas as senhas e secrets
- [ ] Configurar SSL/HTTPS
- [ ] Configurar backups automáticos
- [ ] Configurar monitoramento
- [ ] Configurar alertas (uptime, errors, etc)
- [ ] Testar disaster recovery
- [ ] Documentar procedimentos operacionais
- [ ] Configurar CI/CD
- [ ] Realizar testes de carga
- [ ] Configurar rate limiting
- [ ] Revisar logs de segurança
- [ ] Configurar CORS adequadamente
- [ ] Testar processo de rollback
- [ ] Validar backups regularmente

## 🆘 Troubleshooting Avançado

### Alto uso de CPU

```bash
# Ver quais processos estão usando CPU
docker stats

# Dentro do container
docker compose exec backend sh
top
```

### Memória insuficiente

```bash
# Ver uso de memória
docker stats

# Aumentar limite
docker compose up -d --scale backend=1 --memory=2g
```

### Disk Space

```bash
# Ver uso de disco
docker system df

# Limpar tudo (cuidado!)
docker system prune -a --volumes
```

## 📚 Recursos Adicionais

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Node.js in Production](https://nodejs.org/en/docs/guides/nodejs-docker-webapp/)
- [Next.js Deployment](https://nextjs.org/docs/deployment)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [MedusaJS Documentation](https://docs.medusajs.com/)
