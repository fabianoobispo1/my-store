# 🐳 Guia Docker - MedusaJS 2.0 Completo

Este guia ensina como executar todo o projeto MedusaJS em containers Docker, incluindo todos os serviços necessários (PostgreSQL, Redis, MinIO, MeiliSearch).

## 📦 O que está incluído?

- **PostgreSQL** - Banco de dados principal
- **Redis** - Cache e filas de trabalho
- **MinIO** - Armazenamento S3-compatible para mídia
- **MeiliSearch** - Motor de busca
- **Backend (MedusaJS)** - API e Admin Dashboard
- **Storefront (Next.js)** - Loja online

## 🚀 Início Rápido

### 1. Configurar Variáveis de Ambiente

```bash
# Copiar arquivo de exemplo
cp .env.example .env

# Editar o arquivo .env e alterar as senhas
nano .env  # ou use seu editor favorito
```

**IMPORTANTE:** Altere os valores com `_change_me` no arquivo `.env`!

### 2. Obter Publishable Key

O storefront precisa de uma chave de API. Siga estes passos:

```bash
# Iniciar apenas os serviços de infraestrutura + backend
docker compose up -d postgres redis minio minio-setup meilisearch backend

# Aguardar o backend iniciar (cerca de 1-2 minutos)
docker compose logs -f backend
# Aguarde até ver mensagens indicando que o servidor está rodando
```

Agora acesse o Admin Dashboard:
1. Abra: http://localhost:9000/app
2. Faça login com as credenciais definidas em `.env`:
   - Email: `MEDUSA_ADMIN_EMAIL`
   - Senha: `MEDUSA_ADMIN_PASSWORD`
3. Vá em **Settings → Publishable API Keys**
4. Copie a chave (ou crie uma nova)
5. Cole no arquivo `.env` em `NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY`

### 3. Iniciar Tudo

```bash
# Parar os serviços
docker compose down

# Iniciar todos os serviços
docker compose up -d

# Ver logs em tempo real
docker compose logs -f

# Ver apenas logs do backend
docker compose logs -f backend

# Ver apenas logs do storefront
docker compose logs -f storefront
```

### 4. Acessar os Serviços

- **Storefront:** http://localhost:8000
- **Admin Dashboard:** http://localhost:9000/app
- **Backend API:** http://localhost:9000
- **MinIO Console:** http://localhost:9011 (login: minioadmin / minioadmin_change_me)
- **MeiliSearch:** http://localhost:7700

## 🔧 Comandos Úteis

### Gerenciamento de Containers

```bash
# Ver status de todos os containers
docker compose ps

# Parar todos os serviços
docker compose down

# Parar e remover volumes (APAGA DADOS!)
docker compose down -v

# Reiniciar um serviço específico
docker compose restart backend

# Ver logs de um serviço
docker compose logs backend

# Executar comando dentro do container
docker compose exec backend sh
```

### Rebuild de Imagens

```bash
# Rebuild apenas do backend
docker compose build backend

# Rebuild apenas do storefront
docker compose build storefront

# Rebuild tudo
docker compose build

# Rebuild e reiniciar
docker compose up -d --build
```

### Backup e Restore

```bash
# Backup do banco de dados
docker compose exec postgres pg_dump -U medusa medusa > backup.sql

# Restore do banco de dados
docker compose exec -T postgres psql -U medusa medusa < backup.sql

# Listar volumes
docker volume ls

# Backup de um volume (exemplo: postgres)
docker run --rm -v my-store_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres-backup.tar.gz -C /data .
```

## 🌍 Configuração para Produção

### 1. Domínios e SSL

Para produção, você precisa:
1. Configurar um reverse proxy (Nginx, Traefik, Caddy)
2. Obter certificados SSL (Let's Encrypt via Certbot)
3. Atualizar as variáveis de ambiente

Exemplo de configuração `.env` para produção:

```env
# Backend
NEXT_PUBLIC_MEDUSA_BACKEND_URL=https://api.seudominio.com
BACKEND_PORT=9000

# Storefront
NEXT_PUBLIC_BASE_URL=https://seudominio.com
STOREFRONT_PORT=8000

# CORS
ADMIN_CORS=https://api.seudominio.com,https://admin.seudominio.com
STORE_CORS=https://seudominio.com
AUTH_CORS=https://api.seudominio.com,https://admin.seudominio.com

# MinIO
MINIO_PUBLIC_URL=https://minio.seudominio.com

# Search
NEXT_PUBLIC_SEARCH_ENDPOINT=https://search.seudominio.com
```

### 2. Exemplo de Nginx Reverse Proxy

```nginx
# /etc/nginx/sites-available/medusa

# Backend API + Admin
server {
    listen 80;
    server_name api.seudominio.com;
    
    location / {
        proxy_pass http://localhost:9000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

# Storefront
server {
    listen 80;
    server_name seudominio.com www.seudominio.com;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

# MinIO
server {
    listen 80;
    server_name minio.seudominio.com;
    
    location / {
        proxy_pass http://localhost:9010;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
}
```

Depois configure SSL com Certbot:
```bash
sudo certbot --nginx -d seudominio.com -d www.seudominio.com -d api.seudominio.com -d minio.seudominio.com
```

### 3. Segurança

**CRÍTICO para produção:**

1. **Altere todas as senhas e secrets** no `.env`
2. **Use senhas fortes** (mínimo 32 caracteres aleatórios)
3. **Não exponha portas desnecessárias** - remova as seções `ports` dos serviços internos
4. **Configure firewall** - apenas 80 e 443 públicos
5. **Habilite backups automáticos**
6. **Use Docker secrets** em vez de `.env` se usar Docker Swarm

## 🐛 Troubleshooting

### Backend não inicia

```bash
# Ver logs detalhados
docker compose logs backend

# Problemas comuns:
# 1. Banco de dados não está pronto
#    Solução: aguarde 30s e tente novamente

# 2. Migrações falharam
#    Solução: limpe e recrie o banco
docker compose down -v
docker compose up -d

# 3. Cache de configuração
#    Solução: rebuild da imagem
docker compose build backend --no-cache
```

### Storefront não conecta ao backend

```bash
# Verifique se o backend está rodando
curl http://localhost:9000/health

# Verifique se a PUBLISHABLE_KEY está correta
docker compose logs storefront | grep -i "publishable"

# Verifique as variáveis de ambiente
docker compose exec storefront printenv | grep MEDUSA
```

### MinIO não acessa imagens

```bash
# Verifique se o bucket foi criado
docker compose logs minio-setup

# Acesse o console do MinIO
# http://localhost:9011

# Recrie o setup do MinIO
docker compose up -d --force-recreate minio-setup
```

### MeiliSearch não indexa produtos

```bash
# Ver logs do MeiliSearch
docker compose logs meilisearch

# Verificar se o backend consegue conectar
docker compose exec backend sh
wget -O- http://meilisearch:7700/health
```

## 📊 Monitoramento

### Ver uso de recursos

```bash
# Uso de CPU e memória
docker stats

# Espaço em disco dos volumes
docker system df -v

# Logs por período
docker compose logs --since 1h backend
docker compose logs --tail 100 backend
```

## 🔄 Atualizações

### Atualizar versão do MedusaJS

1. Edite `backend/package.json` e atualize as versões
2. Rebuild da imagem:
```bash
docker compose build backend --no-cache
docker compose up -d backend
```

### Atualizar versão do Next.js

1. Edite `storefront/package.json`
2. Rebuild da imagem:
```bash
docker compose build storefront --no-cache
docker compose up -d storefront
```

## 📚 Aprendendo Docker

### Conceitos importantes:

- **Container**: Instância isolada da aplicação
- **Imagem**: Template para criar containers
- **Volume**: Armazenamento persistente de dados
- **Network**: Rede isolada para comunicação entre containers
- **Compose**: Orquestração de múltiplos containers

### Recursos de aprendizado:

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 💡 Dicas

1. **Development vs Production**: Use `docker-compose.override.yml` para configurações locais
2. **Hot Reload**: Monte volumes para desenvolvimento com `./backend:/app` 
3. **Multi-stage builds**: Os Dockerfiles já usam para otimizar tamanho
4. **Health checks**: Todos os serviços têm health checks configurados
5. **Dependências**: O compose aguarda serviços estarem saudáveis antes de iniciar dependentes

## 🆘 Suporte

Se encontrar problemas:

1. Verifique os logs: `docker compose logs -f`
2. Verifique o status: `docker compose ps`
3. Recrie os containers: `docker compose up -d --force-recreate`
4. Em último caso: `docker compose down -v && docker compose up -d` (apaga dados!)

---

**Pronto!** Agora você tem um ambiente completo rodando em Docker! 🎉
