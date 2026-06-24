#!/bin/bash
# Registra el webhook de Telegram con la URL actual del túnel
# Se ejecuta automáticamente tras arrancar cloudflared

source /home/coke/bot-recetas/.env

BOT_TOKEN="$BOT_TOKEN"
SECRET="uNuvb2QrghJR9dVf_tg-trigger"

# Esperar hasta que cloudflared tenga URL
TUNNEL_URL=""
for i in $(seq 1 30); do
  TUNNEL_URL=$(journalctl -u cloudflared -n 50 --no-pager 2>/dev/null | grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' | tail -1)
  [ -n "$TUNNEL_URL" ] && break
  sleep 2
done

if [ -z "$TUNNEL_URL" ]; then
  echo "ERROR: No se pudo obtener la URL del túnel"
  exit 1
fi

echo "Tunnel URL: $TUNNEL_URL"

# Esperar a que n8n esté listo
for i in $(seq 1 30); do
  curl -s http://localhost:5678/healthz | grep -q "ok" && break
  sleep 2
done

# Registrar webhook
RESULT=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/setWebhook?url=${TUNNEL_URL}/webhook/bot-recetas-main/webhook&secret_token=${SECRET}")
echo "Webhook: $RESULT"
