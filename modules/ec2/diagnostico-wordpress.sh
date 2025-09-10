#!/bin/bash

echo "🔍 Diagnóstico WordPress - ALB 502 Error"
echo "========================================"

# Verificar se Docker está rodando
echo "🐳 Status do Docker:"
sudo systemctl status docker --no-pager -l

# Verificar containers em execução
echo ""
echo "📦 Containers em execução:"
sudo docker ps -a

# Verificar logs do WordPress
echo ""
echo "📝 Logs do WordPress (últimas 20 linhas):"
sudo docker logs wordpress --tail 20 2>/dev/null || echo "Container wordpress não encontrado"

# Verificar logs do MySQL
echo ""
echo "🗄️  Logs do MySQL (últimas 20 linhas):"
sudo docker logs mysql --tail 20 2>/dev/null || echo "Container mysql não encontrado"

# Verificar logs do Traefik
echo ""
echo "🔗 Logs do Traefik (últimas 20 linhas):"
sudo docker logs traefik --tail 20 2>/dev/null || echo "Container traefik não encontrado"

# Testar conectividade local
echo ""
echo "🌐 Testando conectividade local:"
echo "  - Porta 8000 (WordPress):"
curl -I http://localhost:8000 2>/dev/null | head -1 || echo "    ❌ Falha na porta 8000"

echo "  - Porta 80 (Traefik):"
curl -I http://localhost:80 2>/dev/null | head -1 || echo "    ❌ Falha na porta 80"

echo "  - Porta 3306 (MySQL):"
nc -z localhost 3306 && echo "    ✅ MySQL respondendo" || echo "    ❌ MySQL não responde"

# Verificar processes
echo ""
echo "🔧 Processos Docker:"
sudo docker compose ps 2>/dev/null || echo "Docker Compose não encontrado"

# Verificar espaço em disco
echo ""
echo "💾 Espaço em disco:"
df -h | grep -E "(Filesystem|/dev/|tmpfs)"

# Verificar network
echo ""
echo "🔌 Network Docker:"
sudo docker network ls

# Status geral do sistema
echo ""
echo "⚡ Status do sistema:"
echo "  - Load average: $(uptime | awk -F'load average:' '{print $2}')"
echo "  - Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"

echo ""
echo "✅ Diagnóstico concluído!"
echo ""
echo "🎯 Próximos passos se 502 persistir:"
echo "1. Aguarde 10-15 minutos para WordPress inicializar"
echo "2. Reinicie containers: ./restart-wordpress.sh"
echo "3. Verifique se ALB target está healthy no AWS Console"
