#!/bin/sh
set -e

echo "🚀 Starting Medusa Backend..."

# Verificar se o banco já foi inicializado
if ! pnpm exec medusa migrations show 2>/dev/null | grep -q "Pending migrations: 0"; then
    echo "📦 First time setup detected! Running migrations and seeding..."
    pnpm ib
else
    echo "✅ Database already initialized, starting server..."
fi

# Iniciar o servidor
exec pnpm dev
