# 🚀 Infraestrutura WordPress na AWS

Projeto Terraform para deploy automatizado do WordPress com arquitetura segura na AWS.

## 🏗️ Arquitetura

```
Internet → ALB → EC2 (subnet privada)
```

### Componentes:
- **EC2**: Instância em subnet privada executando WordPress + MySQL + Traefik via Docker
- **ALB**: Application Load Balancer em subnets públicas  
- **VPC**: Rede privada com subnets públicas e privadas
- **Security Groups**: Regras de firewall restritivas
- **Docker Stack**: WordPress + MySQL + Traefik com volumes persistentes

## 🌐 URLs de Acesso

### Após Deploy:
```
http://[ALB-DNS-NAME]               # WordPress principal
http://[ALB-DNS-NAME]/wp-admin      # WordPress admin
http://[ALB-DNS-NAME]/wp-admin/install.php  # Instalação inicial
```

## 🔧 Deploy

### Via GitHub Actions:
1. Configure os secrets no GitHub:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

2. Execute o workflow:
   - Acesse: Actions → "🚀 WordPress Terraform CI/CD Pipeline"
   - Selecione: "Run workflow" → "apply"

### Via CLI Local:
```bash
terraform init
terraform plan
terraform apply
```

## 📋 Configurações

### Principais variáveis (terraform.tfvars):
```hcl
ec2_name = "wordpress-server"
region = "us-east-1"
vpc_cidr = "10.0.0.0/16"
environment = "production"
ec2_instance_type = "t3.medium"
```

### Docker Stack:
```yaml
services:
  wordpress:
    image: wordpress:latest
    ports: ["8000:80"]
    environment:
      - WORDPRESS_DB_HOST=mysql
      - WORDPRESS_DB_NAME=wordpress
      - WORDPRESS_DB_USER=wpuser
      - WORDPRESS_DB_PASSWORD=wppassword
  
  mysql:
    image: mysql:8.0
    environment:
      - MYSQL_DATABASE=wordpress
      - MYSQL_USER=wpuser
      - MYSQL_PASSWORD=wppassword
      - MYSQL_ROOT_PASSWORD=rootpassword
  
  traefik:
    image: traefik:v3.0
    ports: ["80:80", "8080:8080"]
```

## 🚨 Troubleshooting

### Erro 502 (Bad Gateway):
1. **Aguarde**: WordPress + MySQL demoram 5-10 min para inicializar completamente
2. **Verifique containers**: Acesse via SSM e rode `docker compose ps`
3. **Reinicie stack**: Use o script `./restart-wordpress.sh`

### ALB Health Check Failed:
1. **Verifique porta 8000**: WordPress deve responder na porta 8000
2. **Check MySQL**: MySQL deve estar healthy antes do WordPress
3. **Logs dos containers**: `docker compose logs wordpress` e `docker compose logs mysql`

### Comandos úteis:
```bash
# Via AWS Session Manager
aws ssm start-session --target <instance-id>

# Verificar status dos containers
docker compose ps
docker compose logs -f wordpress
docker compose logs -f mysql

# Reiniciar WordPress stack
cd wordpress-project
./restart-wordpress.sh

# Testar conectividade local
curl -I http://localhost:8000
curl -I http://localhost:80
```

## 📁 Estrutura do Projeto

```
├── main.tf                    # Configuração principal
├── variables.tf               # Variáveis globais
├── terraform.tfvars          # Valores das variáveis
├── outputs.tf                # Outputs da infraestrutura
├── modules/
│   ├── network/              # VPC, subnets, gateways
│   ├── ec2/                  # Instâncias e configuração WordPress
│   │   ├── user_data.sh      # Script de inicialização WordPress
│   │   ├── compose.yaml      # Docker Compose WordPress
│   │   └── restart-wordpress.sh # Script de restart
│   ├── alb/                  # Application Load Balancer
│   ├── s3/                   # Buckets S3
│   └── sg/                   # Security Groups
└── .github/
    └── workflows/            # GitHub Actions pipelines
        ├── deploy.yml        # Deploy pipeline
        ├── destroy.yml       # Destroy pipeline
        └── test.yml          # Test pipeline
```

## 🔒 Segurança

- EC2 em subnet privada (sem IP público)
- Acesso externo apenas via ALB
- Security Groups com regras mínimas
- Volumes EBS criptografados
- IAM roles com princípio do menor privilégio
- MySQL com senha segura
- WordPress com volumes persistentes

## ⚡ Performance

- ALB para balanceamento de carga
- Instância otimizada com swap
- Docker Compose para gestão de containers
- MySQL com configuração otimizada
- Traefik para proxy reverso

## 💾 Volumes Persistentes

```bash
# Volumes Docker
wordpress_data:/var/www/html     # Arquivos WordPress
mysql_data:/var/lib/mysql        # Dados MySQL

# Backup recomendado
docker exec wordpress tar -czf /tmp/wp-backup.tar.gz /var/www/html
docker exec mysql mysqldump -u wpuser -p wordpress > wp-backup.sql
```

## 👨‍💻 Autor

**Marcelo Menezes**
- GitHub: [@Mfdemenezes](https://github.com/Mfdemenezes)

### Via CLI Local:
```bash
terraform init
terraform plan
terraform apply
```

## 📋 Configurações

### Principais variáveis (terraform.tfvars):
```hcl
ec2_name = "n8n-server"
region = "us-east-1"
vpc_cidr = "10.0.0.0/16"
generic_timezone = "America/Sao_Paulo"
enable_cloudfront = true
```

## 🚨 Troubleshooting

### Erro 502 (Bad Gateway):
1. **Aguarde**: N8N demora 10-15 min para inicializar
2. **Reinicie EC2**: `aws ec2 reboot-instances --instance-ids <instance-id>`
3. **Verifique logs**: Acesse via AWS Console → EC2 → System Log

### Comandos úteis:
```bash
# Ver outputs da infraestrutura
terraform output

# Status da instância
aws ec2 describe-instances --instance-ids <id> --query 'Reservations[0].Instances[0].State.Name'

# Logs do user-data
# (via AWS Console → EC2 → Instance → Actions → Monitor and troubleshoot → Get system log)
```

## 📁 Estrutura do Projeto

```
├── main.tf                    # Configuração principal
├── variables.tf               # Variáveis globais
├── terraform.tfvars          # Valores das variáveis
├── outputs.tf                # Outputs da infraestrutura
├── modules/
│   ├── network/              # VPC, subnets, gateways
│   ├── ec2/                  # Instâncias e configuração N8N
│   ├── alb/                  # Application Load Balancer
│   ├── cloudfront/           # CloudFront distribution
│   ├── s3/                   # Buckets S3
│   └── sg/                   # Security Groups
└── .github/
    └── workflows/            # GitHub Actions pipelines
```

## 🔒 Segurança

- EC2 em subnet privada (sem IP público)
- Acesso externo apenas via CloudFront
- Security Groups com regras mínimas
- Volumes EBS criptografados
- IAM roles com princípio do menor privilégio

## ⚡ Performance

- CloudFront para cache global
- ALB para balanceamento de carga
- Instância otimizada com swap
- Docker Compose para gestão de containers

## 👨‍💻 Autor

**Marcelo Menezes**
- GitHub: [@Mfdemenezes](https://github.com/Mfdemenezes)
