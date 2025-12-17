# 📦 Arquivos Docker - Resumo

Este documento lista todos os arquivos relacionados ao Docker criados para containerizar o projeto MedusaJS.

## 📁 Estrutura de Arquivos

```
my-store/
├── 🐳 Docker Configuration
│   ├── docker-compose.yml              # Configuração principal (dev + prod)
│   ├── docker-compose.override.yml     # Override para desenvolvimento local
│   ├── docker-compose.prod.yml         # Configurações específicas de produção
│   ├── .env.example                    # Template de variáveis de ambiente
│   └── .gitignore                      # Atualizado para ignorar .env
│
├── 🔧 Scripts Auxiliares
│   ├── setup-docker.sh                 # Script de setup inicial interativo
│   └── Makefile                        # Comandos simplificados (make dev, make logs, etc)
│
├── 📚 Documentação
│   ├── DOCKER.md                       # Guia completo de uso do Docker
│   ├── OPTIMIZATION.md                 # Otimizações e boas práticas
│   ├── CLOUD-DEPLOY.md                 # Deploy em cloud providers
│   └── README.md                       # Atualizado com seção Docker
│
├── backend/
│   ├── Dockerfile                      # Build de produção (multi-stage)
│   ├── Dockerfile.dev                  # Build de desenvolvimento com hot-reload
│   └── .dockerignore                   # Arquivos ignorados no build
│
└── storefront/
    ├── Dockerfile                      # Build de produção (Next.js standalone)
    ├── Dockerfile.dev                  # Build de desenvolvimento com hot-reload
    ├── .dockerignore                   # Arquivos ignorados no build
    └── next.config.js                  # Atualizado com output: 'standalone'
```

## 🎯 Principais Componentes

### 1. Docker Compose (docker-compose.yml)
Define 6 serviços:
- ✅ **PostgreSQL** - Banco de dados
- ✅ **Redis** - Cache e filas
- ✅ **MinIO** - Armazenamento S3-compatible
- ✅ **MinIO Setup** - Cria bucket automaticamente
- ✅ **MeiliSearch** - Motor de busca
- ✅ **Backend** - MedusaJS API + Admin
- ✅ **Storefront** - Next.js 15

### 2. Dockerfiles

#### Backend (Multi-stage build)
```dockerfile
1. base      → Instala pnpm
2. deps      → Instala dependências
3. builder   → Build do projeto
4. runner    → Imagem final otimizada
```

#### Storefront (Multi-stage build)
```dockerfile
1. base      → Instala pnpm
2. deps      → Instala dependências
3. builder   → Build Next.js com standalone
4. runner    → Imagem final otimizada
```

### 3. Variáveis de Ambiente (.env.example)

60+ variáveis documentadas em categorias:
- 🗄️ PostgreSQL
- 🔴 Redis
- 📦 MinIO
- 🔍 MeiliSearch
- 🏗️ Backend (MedusaJS)
- 🛍️ Storefront (Next.js)
- 💳 Payment providers (Stripe)
- 📧 Email providers (Resend/SendGrid)

### 4. Scripts Auxiliares

#### setup-docker.sh
Script interativo que:
1. Verifica se Docker está instalado
2. Cria .env a partir do template
3. Inicia serviços de infraestrutura
4. Guia o usuário para obter Publishable Key
5. Finaliza setup completo

#### Makefile
30+ comandos simplificados:
```bash
make help              # Ver todos os comandos
make setup             # Setup inicial
make dev               # Iniciar desenvolvimento
make logs              # Ver logs
make backup-db         # Backup do banco
make shell-backend     # Abrir shell no backend
# ... e muito mais
```

## 📖 Documentação

### DOCKER.md (Guia Principal)
- ✅ Início rápido em 4 passos
- ✅ Comandos úteis
- ✅ Backup e restore
- ✅ Configuração para produção
- ✅ Troubleshooting comum
- ✅ Nginx reverse proxy example
- ✅ SSL com Let's Encrypt
- ✅ Checklist de segurança

### OPTIMIZATION.md
- ⚡ Performance tuning (Node.js, PostgreSQL, Redis)
- 🔒 Segurança (secrets, scanning, non-root users)
- 📊 Monitoramento (Prometheus, Grafana)
- 🔄 CI/CD (GitHub Actions example)
- 💾 Backup automático
- 🌐 CDN e caching
- 📱 PWA optimization
- 🎯 Load balancing

### CLOUD-DEPLOY.md
Guias para 11 plataformas:
- 🚂 Railway
- 🎯 Digital Ocean (App Platform + Droplet)
- ☁️ AWS (ECS, EC2, Elastic Beanstalk)
- 🔵 Azure (Container Instances, App Service)
- 🌩️ Google Cloud (Cloud Run, GKE)
- ⎈ Kubernetes
- 🟢 Heroku
- 🔶 Vercel (storefront)
- 🏠 Self-Hosted (Docker Swarm, Portainer)
- 📊 Comparação de plataformas

## 🚀 Como Usar

### Primeira Vez (Setup Completo)
```bash
# 1. Executar script de setup
./setup-docker.sh

# 2. Seguir instruções para obter Publishable Key
# 3. Reiniciar tudo
make restart

# 4. Acessar
# - Storefront: http://localhost:8000
# - Admin: http://localhost:9000/app
```

### Desenvolvimento Diário
```bash
make dev        # Inicia tudo
make logs       # Ver logs
make restart    # Reiniciar
make down       # Parar
```

### Produção
```bash
# 1. Configurar .env para produção
# 2. Deploy
make prod

# 3. Ou usar arquivo específico
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## ✨ Features Destacadas

### 1. Hot Reload em Desenvolvimento
```bash
make dev
# Edite arquivos em backend/src ou storefront/src
# Mudanças são refletidas instantaneamente
```

### 2. Health Checks
Todos os serviços têm health checks configurados:
- PostgreSQL verifica conexão
- Redis verifica ping
- MinIO verifica endpoint
- MeiliSearch verifica /health
- Backend verifica /health

### 3. Setup Automático do MinIO
Container `minio-setup` automaticamente:
- Cria bucket `medusa-media`
- Configura política pública
- Executa uma única vez

### 4. Volumes Persistentes
Dados persistidos automaticamente:
- `postgres_data` → Banco de dados
- `redis_data` → Cache Redis
- `minio_data` → Arquivos de mídia
- `meilisearch_data` → Índices de busca
- `backend_uploads` → Uploads locais (fallback)

### 5. Network Isolada
Todos os containers na rede `medusa-network`:
- Comunicação interna por nome de serviço
- Isolamento de outros containers
- Configurável para produção

## 🔐 Segurança

### Implementações de Segurança
✅ **Non-root users** - Todos os containers rodam como usuário não-privilegiado
✅ **Multi-stage builds** - Imagens finais não contêm ferramentas de build
✅ **Health checks** - Detecção automática de problemas
✅ **.dockerignore** - Não incluir arquivos sensíveis
✅ **.gitignore** - Não commitar .env
✅ **Secrets ready** - Suporta Docker Secrets em produção

### Para Produção
⚠️ **CRÍTICO:** Altere todas as senhas em `.env`:
- POSTGRES_PASSWORD
- JWT_SECRET
- COOKIE_SECRET
- MINIO_ROOT_PASSWORD
- MEILISEARCH_MASTER_KEY
- MEDUSA_ADMIN_PASSWORD

## 📏 Tamanho das Imagens

Estimativas (após build otimizado):
- **Backend:** ~400-500MB
- **Storefront:** ~200-300MB
- **PostgreSQL:** ~80MB (alpine)
- **Redis:** ~30MB (alpine)
- **MinIO:** ~50MB
- **MeiliSearch:** ~150MB

Total: ~1GB (aplicação)

## 🎓 O Que Você Aprendeu

Ao trabalhar com este setup Docker, você aprendeu:
1. ✅ **Multi-stage builds** para otimizar imagens
2. ✅ **Docker Compose** para orquestrar múltiplos serviços
3. ✅ **Volumes** para persistência de dados
4. ✅ **Networks** para isolamento
5. ✅ **Health checks** para confiabilidade
6. ✅ **Environment variables** para configuração
7. ✅ **Development vs Production** workflows
8. ✅ **Container security** best practices
9. ✅ **Backup e restore** de dados
10. ✅ **Cloud deployment** em diferentes plataformas

## 🔄 Próximos Passos

1. **Experimentar localmente**
   ```bash
   make setup
   ```

2. **Ler a documentação**
   - [DOCKER.md](DOCKER.md) - Guia completo
   - [OPTIMIZATION.md](OPTIMIZATION.md) - Melhorias
   - [CLOUD-DEPLOY.md](CLOUD-DEPLOY.md) - Deploy

3. **Customizar para suas necessidades**
   - Ajustar recursos (CPU, memória)
   - Configurar domínios
   - Adicionar serviços

4. **Deploy em produção**
   - Escolher plataforma
   - Configurar SSL
   - Setup de backups
   - Monitoramento

## 🆘 Precisa de Ajuda?

- 📖 Leia [DOCKER.md](DOCKER.md)
- 🐛 Veja seção Troubleshooting
- 💬 Abra uma issue no GitHub
- 📧 Entre em contato

---

**Parabéns!** Você tem agora um projeto MedusaJS completamente containerizado e pronto para produção! 🎉
