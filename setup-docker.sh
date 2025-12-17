#!/bin/bash

# Script auxiliar para setup inicial do projeto Docker
# Este script facilita a configuração inicial

set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Setup MedusaJS 2.0 - Docker Configuration      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker não está instalado!${NC}"
    echo "Instale Docker Desktop em: https://www.docker.com/products/docker-desktop"
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose não está disponível!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker está instalado${NC}"
echo ""

# Verificar se .env existe
if [ -f .env ]; then
    echo -e "${YELLOW}⚠️  Arquivo .env já existe!${NC}"
    read -p "Deseja sobrescrever? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "Mantendo .env existente"
    else
        cp .env.example .env
        echo -e "${GREEN}✓ Arquivo .env criado a partir do .env.example${NC}"
    fi
else
    cp .env.example .env
    echo -e "${GREEN}✓ Arquivo .env criado a partir do .env.example${NC}"
fi

echo ""
echo -e "${YELLOW}IMPORTANTE:${NC}"
echo "1. Edite o arquivo .env e altere as senhas (valores com _change_me)"
echo "2. Não commite o arquivo .env no git!"
echo ""

read -p "Pressione ENTER para continuar após editar o .env..."

echo ""
echo -e "${BLUE}Iniciando serviços de infraestrutura + backend...${NC}"
docker compose up -d postgres redis minio minio-setup meilisearch

echo ""
echo -e "${YELLOW}Aguardando serviços iniciarem (30s)...${NC}"
sleep 10
echo -e "${YELLOW}Aguardando... 20s${NC}"
sleep 10
echo -e "${YELLOW}Aguardando... 10s${NC}"
sleep 10

echo ""
echo -e "${BLUE}Iniciando backend...${NC}"
docker compose up -d backend

echo ""
echo -e "${YELLOW}Aguardando backend inicializar (60s)...${NC}"
echo "Você pode acompanhar os logs em outra janela: docker compose logs -f backend"
sleep 20
echo -e "${YELLOW}Aguardando... 40s${NC}"
sleep 20
echo -e "${YELLOW}Aguardando... 20s${NC}"
sleep 20

echo ""
echo -e "${GREEN}✓ Backend iniciado!${NC}"
echo ""
echo -e "${YELLOW}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║         PRÓXIMOS PASSOS - IMPORTANTE!             ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "1. Acesse o Admin Dashboard: ${GREEN}http://localhost:9000/app${NC}"
echo ""
echo -e "2. Faça login com as credenciais do .env:"
echo "   - Email: $(grep MEDUSA_ADMIN_EMAIL .env | cut -d= -f2)"
echo "   - Senha: (a senha que você definiu em MEDUSA_ADMIN_PASSWORD)"
echo ""
echo -e "3. Navegue até: ${BLUE}Settings → Publishable API Keys${NC}"
echo ""
echo -e "4. Copie a chave (ou crie uma nova se necessário)"
echo ""
echo -e "5. Edite o arquivo .env e cole a chave em:"
echo "   ${GREEN}NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=sua_chave_aqui${NC}"
echo ""
echo -e "6. Após salvar, execute:"
echo -e "   ${BLUE}docker compose down${NC}"
echo -e "   ${BLUE}docker compose up -d${NC}"
echo ""
echo -e "7. Acesse o storefront: ${GREEN}http://localhost:8000${NC}"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
echo ""
echo "Precisa de ajuda? Leia o arquivo DOCKER.md"
echo ""
