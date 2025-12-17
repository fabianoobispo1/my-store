.PHONY: help setup dev prod build up down logs restart clean backup

# Cores para output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

help: ## Mostra esta mensagem de ajuda
	@echo "$(BLUE)╔════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║   MedusaJS 2.0 Docker - Comandos Disponíveis     ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

setup: ## Configuração inicial (cria .env e inicia setup)
	@./setup-docker.sh

dev: ## Inicia ambiente de desenvolvimento com hot-reload
	@echo "$(BLUE)Iniciando ambiente de desenvolvimento...$(NC)"
	@docker compose up -d
	@echo "$(GREEN)✓ Ambiente iniciado!$(NC)"
	@echo ""
	@echo "  - Admin: $(BLUE)http://localhost:9000/app$(NC)"
	@echo "  - Store: $(BLUE)http://localhost:8000$(NC)"
	@echo "  - MinIO: $(BLUE)http://localhost:9011$(NC)"
	@echo ""
	@echo "Logs: $(YELLOW)make logs$(NC)"

prod: ## Inicia ambiente de produção
	@echo "$(BLUE)Iniciando ambiente de produção...$(NC)"
	@docker compose -f docker-compose.yml up -d
	@echo "$(GREEN)✓ Ambiente iniciado!$(NC)"

build: ## Rebuild das imagens
	@echo "$(BLUE)Rebuilding imagens...$(NC)"
	@docker compose build
	@echo "$(GREEN)✓ Build completo!$(NC)"

build-no-cache: ## Rebuild das imagens sem cache
	@echo "$(BLUE)Rebuilding imagens sem cache...$(NC)"
	@docker compose build --no-cache
	@echo "$(GREEN)✓ Build completo!$(NC)"

up: ## Inicia todos os containers
	@docker compose up -d

down: ## Para todos os containers
	@echo "$(YELLOW)Parando containers...$(NC)"
	@docker compose down
	@echo "$(GREEN)✓ Containers parados!$(NC)"

logs: ## Mostra logs de todos os containers
	@docker compose logs -f

logs-backend: ## Mostra logs do backend
	@docker compose logs -f backend

logs-storefront: ## Mostra logs do storefront
	@docker compose logs -f storefront

restart: ## Reinicia todos os containers
	@echo "$(BLUE)Reiniciando containers...$(NC)"
	@docker compose restart
	@echo "$(GREEN)✓ Containers reiniciados!$(NC)"

restart-backend: ## Reinicia apenas o backend
	@docker compose restart backend

restart-storefront: ## Reinicia apenas o storefront
	@docker compose restart storefront

status: ## Mostra status dos containers
	@docker compose ps

clean: ## Remove containers e volumes (APAGA DADOS!)
	@echo "$(YELLOW)⚠️  ATENÇÃO: Isso vai apagar TODOS os dados!$(NC)"
	@read -p "Tem certeza? (digite 'yes' para confirmar): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		docker compose down -v; \
		echo "$(GREEN)✓ Limpeza completa!$(NC)"; \
	else \
		echo "$(YELLOW)Cancelado.$(NC)"; \
	fi

backup-db: ## Backup do banco de dados
	@echo "$(BLUE)Criando backup do banco de dados...$(NC)"
	@mkdir -p backups
	@docker compose exec -T postgres pg_dump -U medusa medusa > backups/db-backup-$$(date +%Y%m%d-%H%M%S).sql
	@echo "$(GREEN)✓ Backup criado em backups/$(NC)"

restore-db: ## Restore do banco de dados (use: make restore-db FILE=backup.sql)
	@if [ -z "$(FILE)" ]; then \
		echo "$(RED)Erro: especifique o arquivo com FILE=caminho$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Restaurando banco de dados de $(FILE)...$(NC)"
	@docker compose exec -T postgres psql -U medusa medusa < $(FILE)
	@echo "$(GREEN)✓ Banco restaurado!$(NC)"

shell-backend: ## Abre shell no container do backend
	@docker compose exec backend sh

shell-storefront: ## Abre shell no container do storefront
	@docker compose exec storefront sh

shell-db: ## Abre psql no banco de dados
	@docker compose exec postgres psql -U medusa medusa

stats: ## Mostra uso de recursos dos containers
	@docker stats

prune: ## Remove imagens e volumes não utilizados
	@echo "$(YELLOW)Removendo recursos não utilizados...$(NC)"
	@docker system prune -f
	@echo "$(GREEN)✓ Limpeza concluída!$(NC)"
