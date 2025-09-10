#!/bin/bash

# Script para reiniciar WordPress e MySQL
# Uso: ./restart-wordpress.sh

echo "🔄 Reiniciando WordPress..."

# Parar containers
echo "⏹️  Parando containers..."
docker compose down

# Aguardar um momento
echo "⏳ Aguardando 10 segundos..."
sleep 10

# Limpar containers parados e imagens não utilizadas
echo "🧹 Limpando recursos..."
docker system prune -f

# Iniciar containers novamente
echo "🚀 Iniciando WordPress..."
docker compose up -d

# Aguardar containers subirem
echo "⏳ Aguardando containers iniciarem..."
sleep 30

# Verificar status
echo "📊 Status dos containers:"
docker compose ps

# Testar conectividade
echo "🔍 Testando conectividade..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 | grep -q "200\|302"; then
    echo "✅ WordPress está respondendo!"
else
    echo "❌ WordPress não está respondendo"
    echo "📋 Logs do WordPress:"
    docker compose logs --tail=20 wordpress
fi

echo "✅ Reinicialização concluída!"
echo "🌐 Acesse: http://[ALB-DNS-NAME]"
