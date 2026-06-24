#!/bin/bash
# Ejecutar en la Raspberry Pi tras el primer arranque
# curl -sL https://<tu-tunnel>/setup-pi.sh | bash

set -e
echo "=== Setup Raspberry Pi - Bot Recetas ==="

# Actualizar sistema
echo ">>> Actualizando sistema..."
sudo apt-get update -qq && sudo apt-get upgrade -y -qq

# Instalar Docker
echo ">>> Instalando Docker..."
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Instalar Docker Compose plugin
echo ">>> Instalando Docker Compose..."
sudo apt-get install -y docker-compose-plugin

# Crear directorio del proyecto
mkdir -p ~/bot-recetas
cd ~/bot-recetas

echo ""
echo "=== Setup completado ==="
echo "Ahora:"
echo "  1. Copia docker-compose.yml y .env a ~/bot-recetas/"
echo "  2. Ejecuta: docker compose up -d"
echo ""
echo "IMPORTANTE: Cierra la sesión SSH y vuelve a entrar"
echo "para que el grupo docker tenga efecto."
