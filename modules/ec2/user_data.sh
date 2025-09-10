#!/bin/bash

# Log de execução
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Iniciando configuração do servidor WordPress ==="
date

# Atualizar sistema
echo "=== Atualizando sistema ==="
yum update -y

# Instalar Docker
echo "=== Instalando Docker ==="
yum install -y docker git
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Instalar Docker Compose v2
echo "=== Instalando Docker Compose v2 ==="
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Criar link simbólico para compatibilidade
ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

# Adicionar swap para melhor performance
echo "=== Configurando swap ==="
dd if=/dev/zero of=/swapfile bs=128M count=32
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

# Criar diretório para o projeto WordPress
echo "=== Configurando diretório do projeto ==="
mkdir -p /home/ec2-user/wordpress-project
cd /home/ec2-user/wordpress-project

# Copiar o compose.yaml do módulo terraform
echo "=== Criando docker-compose.yml ==="
cat > docker-compose.yml << 'EOFCOMPOSE'
services:
  traefik:
    container_name: traefik 
    image: "traefik:v3.0"
    restart: always
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.mytlschallenge.acme.tlschallenge=true"
      - "--certificatesresolvers.mytlschallenge.acme.email=admin@example.com"
      - "--certificatesresolvers.mytlschallenge.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - ./acme.json:/letsencrypt/acme.json
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - wordpress-network

  mysql:
    image: mysql:8.0
    container_name: wordpress_mysql
    restart: always
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: wppassword
      MYSQL_ROOT_PASSWORD: rootpassword
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - wordpress-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10

  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: always
    depends_on:
      - mysql
    ports:
      - "8000:80"
    labels:
      - traefik.enable=true
      - traefik.http.routers.wordpress.rule=Host(`localhost`) || PathPrefix(`/`)
      - traefik.http.routers.wordpress.entrypoints=web
      - traefik.http.services.wordpress.loadbalancer.server.port=80
    environment:
      WORDPRESS_DB_HOST: mysql:3306
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: wpuser
      WORDPRESS_DB_PASSWORD: wppassword
      WORDPRESS_TABLE_PREFIX: wp_
      WORDPRESS_DEBUG: 1
    volumes:
      - wordpress_data:/var/www/html
      - ./uploads.ini:/usr/local/etc/php/conf.d/uploads.ini
    networks:
      - wordpress-network
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  mysql_data:
    driver: local
  wordpress_data:
    driver: local

networks:
  wordpress-network:
    driver: bridge
EOFCOMPOSE

# Criar arquivo .env
echo "=== Criando arquivo .env ==="
cat > .env << EOFENV
# Configurações WordPress
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=wppassword
MYSQL_ROOT_PASSWORD=rootpassword
WORDPRESS_DB_HOST=mysql:3306
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wpuser
WORDPRESS_DB_PASSWORD=wppassword
EOFENV

# Criar arquivo uploads.ini para PHP
echo "=== Criando arquivo uploads.ini ==="
cat > uploads.ini << EOFUPLOADS
file_uploads = On
memory_limit = 512M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 600
EOFUPLOADS

# Criar arquivo acme.json para certificados SSL
echo "=== Criando arquivo acme.json ==="
touch acme.json
chmod 600 acme.json

# Criar diretório para arquivos locais
echo "=== Criando estrutura de diretórios ==="
mkdir -p local-files

# Criar script de restart
echo "=== Criando script de restart ==="
cat > restart-wordpress.sh << 'EOFRESTART'
#!/bin/bash
echo "=== Script de Restart do WordPress ==="
date
cd /home/ec2-user/wordpress-project || exit 1
echo "=== Parando containers existentes ==="
docker compose down --remove-orphans
echo "=== Limpando recursos órfãos ==="
docker system prune -f
docker network prune -f
echo "=== Fazendo pull das imagens ==="
docker compose pull
echo "=== Iniciando containers ==="
docker compose up -d
echo "=== Aguardando inicialização ==="
sleep 60
echo "=== Status dos containers ==="
docker ps
docker compose ps
echo "=== Logs recentes ==="
docker compose logs --tail 10
echo "=== Testando conectividade ==="
curl -I http://localhost:8000 2>/dev/null && echo "✅ WordPress OK" || echo "❌ WordPress Fail"
curl -I http://localhost:80 2>/dev/null && echo "✅ Traefik OK" || echo "❌ Traefik Fail"
echo "=== Script concluído ==="
date
EOFRESTART

chmod +x restart-wordpress.sh

chown -R ec2-user:ec2-user /home/ec2-user/wordpress-project

# Aguardar o Docker estar pronto e configurar permissões
echo "=== Configurando Docker e permissões ==="
sleep 10
systemctl restart docker
sleep 5

# Garantir que ec2-user tenha acesso ao Docker
usermod -a -G docker ec2-user
newgrp docker

# Testar Docker
echo "=== Testando Docker ==="
docker --version
docker info

# Testar Docker Compose
echo "=== Testando Docker Compose ==="
docker compose version

# Executar docker-compose
echo "=== Iniciando WordPress com Docker Compose ==="
cd /home/ec2-user/wordpress-project

# Verificar se Docker está rodando
systemctl status docker --no-pager

# Pull das imagens primeiro
echo "=== Fazendo pull das imagens Docker ==="
docker compose pull

# Executar com retry
for i in {1..3}; do
    echo "=== Tentativa $i de executar Docker Compose ==="
    
    # Parar containers existentes se houver
    docker compose down --remove-orphans 2>/dev/null || true
    
    # Limpar redes orfãs
    docker network prune -f
    
    # Executar containers
    docker compose up -d
    
    # Aguardar containers iniciarem
    sleep 30
    
    # Verificar se containers estão rodando
    RUNNING_CONTAINERS=$(docker compose ps --services --filter "status=running" | wc -l)
    
    if [ "$RUNNING_CONTAINERS" -ge 3 ]; then
        echo "✅ Containers executando com sucesso!"
        break
    else
        echo "❌ Tentativa $i falhou, containers não estão rodando"
        echo "=== Debug - Lista de containers ==="
        docker ps -a
        echo "=== Debug - Logs do WordPress ==="
        docker compose logs wordpress 2>/dev/null || echo "Sem logs do WordPress"
        echo "=== Debug - Logs do MySQL ==="
        docker compose logs mysql 2>/dev/null || echo "Sem logs do MySQL"
        echo "=== Debug - Logs do Traefik ==="
        docker compose logs traefik 2>/dev/null || echo "Sem logs do Traefik"
        sleep 10
    fi
done

# Aguardar WordPress inicializar
echo "=== Aguardando WordPress inicializar completamente ==="
sleep 90

# Verificar status dos containers várias vezes
for i in {1..5}; do
    echo "=== Verificação $i - Status dos containers ==="
    docker ps
    docker compose ps
    
    # Verificar logs detalhadamente
    echo "=== Logs recentes do WordPress ==="
    docker logs wordpress --tail 10 2>/dev/null || echo "Container WordPress não encontrado"
    
    echo "=== Logs recentes do MySQL ==="
    docker logs wordpress_mysql --tail 10 2>/dev/null || echo "Container MySQL não encontrado"
    
    echo "=== Logs recentes do Traefik ==="
    docker logs traefik --tail 10 2>/dev/null || echo "Container Traefik não encontrado"
    
    # Verificar se containers estão healthy
    HEALTHY_CONTAINERS=$(docker ps --filter "health=healthy" | wc -l)
    echo "Containers healthy: $HEALTHY_CONTAINERS"
    
    sleep 15
done

# Testar conectividade do WordPress
echo "=== Testando conectividade do WordPress ==="
for i in {1..20}; do
    # Testar múltiplas portas
    WORDPRESS_PORT_8000=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:8000 2>/dev/null || echo "000")
    TRAEFIK_PORT_80=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:80 2>/dev/null || echo "000")
    TRAEFIK_DASHBOARD=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:8080 2>/dev/null || echo "000")
    
    echo "Tentativa $i/20:"
    echo "  - WordPress (8000): HTTP $WORDPRESS_PORT_8000"
    echo "  - Traefik (80): HTTP $TRAEFIK_PORT_80"
    echo "  - Dashboard (8080): HTTP $TRAEFIK_DASHBOARD"
    
    if [ "$WORDPRESS_PORT_8000" = "200" ] || [ "$TRAEFIK_PORT_80" = "200" ]; then
        echo "✅ Serviços estão respondendo!"
        break
    elif [ "$WORDPRESS_PORT_8000" = "302" ] || [ "$TRAEFIK_PORT_80" = "302" ]; then
        echo "✅ WordPress rodando (redirecionamento de instalação)!"
        break
    else
        echo "⏳ Aguardando serviços ficarem prontos..."
        sleep 15
    fi
done

# Teste adicional de conectividade interna
echo "=== Teste de conectividade interna dos containers ==="
docker exec wordpress curl -f http://localhost/ && echo "✅ WordPress internal OK" || echo "❌ WordPress internal FAIL"

# Verificar status dos serviços
echo "=== Status final dos serviços ==="
systemctl status docker --no-pager

echo "=== Containers em execução ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo "=== Docker Compose status ==="
cd /home/ec2-user/wordpress-project
docker compose ps

echo "=== Espaço em disco ==="
df -h

echo "=== Memória disponível ==="
free -h

echo "=== Processos Docker ==="
ps aux | grep docker

# Verificação final de funcionamento
echo "=== Verificação final de funcionamento ==="
FINAL_CHECK_WP=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:8000 2>/dev/null || echo "000")
FINAL_CHECK_TRAEFIK=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:80 2>/dev/null || echo "000")

if [ "$FINAL_CHECK_WP" != "000" ] || [ "$FINAL_CHECK_TRAEFIK" != "000" ]; then
    echo "✅ SUCESSO: Serviços WordPress estão funcionando!"
else
    echo "❌ ERRO: Serviços WordPress não estão respondendo"
    echo "=== Debug final ==="
    docker compose logs --tail 20
fi

# Obter IP da instância
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

echo "=== Configuração concluída ==="
echo "✅ WordPress está disponível em:"
echo "   - Direto WordPress: http://$INSTANCE_IP:8000"
echo "   - Via Traefik: http://$INSTANCE_IP:80"
echo "   - Traefik Dashboard: http://$INSTANCE_IP:8080"
echo "   - Instalação WordPress: http://$INSTANCE_IP:8000/wp-admin/install.php"

date
echo "=== Fim da configuração ==="