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

Após o deploy, acesse:
- **URL Principal**: `http://[ALB-DNS-NAME]`
- **WordPress Admin**: `http://[ALB-DNS-NAME]/wp-admin`
- **Instalação Inicial**: `http://[ALB-DNS-NAME]/wp-admin/install.php`

## 🚀 Como usar

### 1. Configurar AWS Credentials
```bash
# Via AWS CLI
aws configure

# Ou via variáveis de ambiente
export AWS_ACCESS_KEY_ID="sua-access-key"
export AWS_SECRET_ACCESS_KEY="sua-secret-key"
```

### 2. Configurar Backend S3
Edite `backend.tf` com seu bucket:
```hcl
terraform {
  backend "s3" {
    bucket = "wordpress-terraform-state-[SEU-NOME]"
    key    = "infra-wordpress/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}
```

### 3. Deploy Local
```bash
terraform init
terraform plan
terraform apply
```

### 4. Deploy via GitHub Actions

#### Configurar Secrets:
1. Vá para **Settings** → **Secrets and variables** → **Actions**
2. Adicione:
   - `AWS_ACCESS_KEY_ID`: Sua AWS Access Key
   - `AWS_SECRET_ACCESS_KEY`: Sua AWS Secret Key

#### Deploy Automático:
```bash
git add .
git commit -m "Deploy WordPress"
git push origin main  # Trigger automático
```

#### Deploy Manual:
1. Acesse **Actions** → **🚀 WordPress Terraform CI/CD Pipeline**
2. Clique **Run workflow** → Selecione **apply**

## 📦 Stack WordPress

### Docker Compose:
```yaml
wordpress:
  image: wordpress:latest
  ports: ["8000:80"]
  environment:
    WORDPRESS_DB_HOST: mysql
    WORDPRESS_DB_NAME: wordpress
    WORDPRESS_DB_USER: wpuser

mysql:
  image: mysql:8.0
  environment:
    MYSQL_DATABASE: wordpress
    MYSQL_USER: wpuser
    MYSQL_ROOT_PASSWORD: rootpassword

traefik:
  image: traefik:v3.0
  ports: ["80:80", "8080:8080"]
```

### Principais Variáveis (terraform.tfvars):
```hcl
ec2_name = "wordpress-server"
region = "us-east-1" 
vpc_cidr = "10.0.0.0/16"
environment = "production"
ec2_instance_type = "t3.medium"
ec2_count = 1
```

## 🛡️ Segurança

- ✅ EC2 em subnet privada (sem IP público)
- ✅ ALB público com SSL pronto
- ✅ Security Groups restritivos
- ✅ Volumes EBS criptografados
- ✅ IAM roles com mínimos privilégios
- ✅ Acesso SSH via AWS Session Manager

## 🚨 Troubleshooting

### WordPress não carrega (502 Error)
```bash
# 1. Aguarde 5-10 minutos (containers inicializando)

# 2. Acesse via SSM
aws ssm start-session --target [INSTANCE-ID]

# 3. Verifique containers
sudo su - ec2-user
cd wordpress-project
docker compose ps
docker compose logs wordpress
docker compose logs mysql

# 4. Reinicie se necessário
./restart-wordpress.sh
```

### ALB Health Check Failed
- **Causa**: MySQL demora para inicializar antes do WordPress
- **Solução**: Aguardar 10-15 minutos ou verificar logs do MySQL

### Erro de Permissões AWS
- **IAM**: Verificar se usuário tem permissões EC2, VPC, ALB, IAM
- **S3**: Verificar acesso ao bucket do backend

## 📁 Estrutura do Projeto

```
├── main.tf                    # Configuração principal
├── variables.tf               # Variáveis globais  
├── terraform.tfvars          # Valores das variáveis
├── outputs.tf                # Outputs da infraestrutura
├── backend.tf                # Backend S3
├── modules/
│   ├── network/              # VPC, subnets, gateways
│   ├── ec2/                  # EC2 + WordPress Docker
│   │   ├── user_data.sh      # Script de inicialização
│   │   ├── compose.yaml      # Docker Compose
│   │   └── restart-wordpress.sh # Script de restart
│   ├── alb/                  # Load Balancer
│   ├── s3/                   # Buckets S3
│   └── sg/                   # Security Groups
└── .github/
    └── workflows/            # CI/CD Pipelines
        ├── deploy.yml        # Deploy
        ├── destroy.yml       # Destroy
        └── test.yml          # Tests
```

## � Workflows GitHub Actions

### Deploy Pipeline
- **Trigger**: Push para `main` ou manual
- **Steps**: Validate → Plan → Apply
- **Output**: URLs de acesso ao WordPress

### Destroy Pipeline  
- **Trigger**: Manual apenas
- **Safety**: Requer digitar "DESTROY"
- **Warning**: Remove toda infraestrutura

### Test Pipeline
- **Trigger**: Manual
- **Function**: Validar sintaxe Terraform

## 💾 Backup e Volumes

### Volumes Persistentes:
```bash
wordpress_data:/var/www/html     # Arquivos WordPress
mysql_data:/var/lib/mysql        # Banco de dados
```

### Backup Manual:
```bash
# Via SSM
aws ssm start-session --target [INSTANCE-ID]

# Backup WordPress
sudo docker exec wordpress tar -czf /tmp/wp-backup.tar.gz /var/www/html

# Backup MySQL  
sudo docker exec mysql mysqldump -u wpuser -p wordpress > wp-backup.sql
```

## 📊 Outputs Importantes

Após deploy bem-sucedido:
- `alb_dns_name`: URL do Load Balancer
- `wordpress_access_urls`: URLs completas de acesso
- `instance_private_ips`: IPs privados das instâncias
- `instance_ids`: IDs das instâncias para SSM

## 🗑️ Destruir Infraestrutura

### Via GitHub Actions:
1. **Actions** → **🗑️ WordPress Terraform Destroy**
2. Digite **DESTROY** na confirmação
3. Selecione ambiente e execute

### Via CLI Local:
```bash
terraform destroy
```

⚠️ **Atenção**: Todos os dados WordPress serão perdidos!

## 👨‍💻 Autor

**Marcelo Menezes**
- GitHub: [@Mfdemenezes](https://github.com/Mfdemenezes)

---

� **Happy WordPressing!** 🚀
