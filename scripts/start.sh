#!/bin/bash
# Bot Recetas - Script de arranque completo
# Uso: bash scripts/start.sh

set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "📁 Proyecto: $PROJECT_DIR"

# Cargar variables de entorno desde .env
ENV_FILE="$PROJECT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
  echo "✅ Variables cargadas desde .env"
else
  echo "⚠️  No se encontró .env — copia .env.example a .env y rellena los valores"
  exit 1
fi

# Verificar n8n
command -v n8n >/dev/null 2>&1 || { echo "❌ n8n no encontrado. Instala: npm install -g n8n"; exit 1; }

# Buscar cloudflared
CLOUDFLARED=""
if command -v cloudflared >/dev/null 2>&1; then
  CLOUDFLARED="cloudflared"
elif [ -f "/tmp/cloudflared" ]; then
  CLOUDFLARED="/tmp/cloudflared"
else
  echo "⚠️  Descargando cloudflared..."
  curl -sL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64.tgz" -o /tmp/cloudflared.tgz
  tar -xzf /tmp/cloudflared.tgz -C /tmp/
  chmod +x /tmp/cloudflared
  CLOUDFLARED="/tmp/cloudflared"
fi

# Limpiar procesos anteriores
echo "🧹 Limpiando procesos anteriores..."
pkill -f "n8n start" 2>/dev/null || true
pkill -f "cloudflared tunnel" 2>/dev/null || true
sleep 2

# Iniciar túnel Cloudflare
echo "🌐 Iniciando túnel Cloudflare..."
$CLOUDFLARED tunnel --url http://localhost:5678 --no-autoupdate > /tmp/cloudflared.log 2>&1 &
CF_PID=$!

# Esperar URL del túnel
TUNNEL_URL=""
for i in $(seq 1 20); do
  TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' /tmp/cloudflared.log 2>/dev/null | head -1)
  [ -n "$TUNNEL_URL" ] && break
  sleep 1
done

if [ -z "$TUNNEL_URL" ]; then
  echo "❌ No se pudo obtener la URL del túnel."
  cat /tmp/cloudflared.log
  exit 1
fi

echo "✅ Túnel: $TUNNEL_URL"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  La URL cambia cada vez que reinicias."
echo "   Tras arrancar n8n, desactiva y reactiva"
echo "   los workflows para que Telegram registre"
echo "   la nueva URL del túnel."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌍 Editor n8n: http://localhost:5678"
echo "🚀 Arrancando n8n con WEBHOOK_URL=$TUNNEL_URL"
echo ""

export WEBHOOK_URL="$TUNNEL_URL"
export DEEPSEEK_API_KEY="$DEEPSEEK_API_KEY"
export OPENROUTER_API_KEY="$OPENROUTER_API_KEY"
export BOT_USERNAME="$BOT_USERNAME"
export N8N_BLOCK_ENV_ACCESS_IN_NODE=false
export NODE_OPTIONS="--dns-result-order=ipv4first"
n8n start
