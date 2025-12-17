# Storefront Dockerfile para Next.js 15
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

# Variáveis de build do Next.js
ARG NEXT_PUBLIC_MEDUSA_BACKEND_URL
ARG NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY
ARG NEXT_PUBLIC_DEFAULT_REGION
ARG NEXT_PUBLIC_BASE_URL
ARG NEXT_PUBLIC_SEARCH_ENDPOINT
ARG NEXT_PUBLIC_SEARCH_API_KEY
ARG NEXT_PUBLIC_INDEX_NAME

ENV NEXT_PUBLIC_MEDUSA_BACKEND_URL=$NEXT_PUBLIC_MEDUSA_BACKEND_URL
ENV NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=$NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY
ENV NEXT_PUBLIC_DEFAULT_REGION=$NEXT_PUBLIC_DEFAULT_REGION
ENV NEXT_PUBLIC_BASE_URL=$NEXT_PUBLIC_BASE_URL
ENV NEXT_PUBLIC_SEARCH_ENDPOINT=$NEXT_PUBLIC_SEARCH_ENDPOINT
ENV NEXT_PUBLIC_SEARCH_API_KEY=$NEXT_PUBLIC_SEARCH_API_KEY
ENV NEXT_PUBLIC_INDEX_NAME=$NEXT_PUBLIC_INDEX_NAME

# Build do projeto Next.js
RUN pnpm build:next

# Stage 3: Runner
FROM base AS runner
WORKDIR /app

# Criar usuário não-root
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copiar arquivos necessários
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json

# Copiar arquivos do build Next.js
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

# Expor porta
EXPOSE 8000

# Variáveis de ambiente padrão
ENV NODE_ENV=production
ENV PORT=8000
ENV HOSTNAME=0.0.0.0

# Comando de inicialização
CMD ["node", "server.js"]
