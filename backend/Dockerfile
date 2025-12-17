# Backend Dockerfile para MedusaJS 2.0
FROM node:22-alpine AS base

# Instalar pnpm
RUN corepack enable && corepack prepare pnpm@9.10.0 --activate

# Stage 1: Dependencies
FROM base AS deps
WORKDIR /app

# Copiar arquivos de dependências
COPY package.json pnpm-lock.yaml ./

# Instalar dependências
RUN pnpm install --frozen-lockfile

# Stage 2: Builder
FROM base AS builder
WORKDIR /app

# Copiar dependências do stage anterior
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build do projeto
RUN pnpm build

# Stage 3: Runner
FROM base AS runner
WORKDIR /app

# Criar usuário não-root
RUN addgroup --system --gid 1001 medusa && \
    adduser --system --uid 1001 medusa

# Copiar dependências de produção
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/.medusa ./.medusa
COPY --from=builder /app/medusa-config.js ./medusa-config.js
COPY --from=builder /app/src ./src

# Ajustar permissões
RUN chown -R medusa:medusa /app

USER medusa

# Expor porta
EXPOSE 9000

# Variáveis de ambiente padrão
ENV NODE_ENV=production
ENV PORT=9000

# Comando de inicialização
CMD ["pnpm", "start"]
