# 🔧 Configuração GitHub Actions - WordPress

## 📋 Pré-requisitos

### 1. AWS Credentials
Você precisa de um usuário IAM na AWS com as seguintes permissões:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "elbv2:*",
                "iam:*",
                "s3:*",
                "ssm:*",
                "logs:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### 2. S3 Bucket para Terraform State
```bash
# Criar bucket para estado do Terraform
aws s3 mb s3://wordpress-terraform-state-[SEU-NOME]
aws s3api put-bucket-versioning --bucket wordpress-terraform-state-[SEU-NOME] --versioning-configuration Status=Enabled
```

## 🔐 Configurar Secrets no GitHub

### 1. Acessar Configurações do Repositório
1. Vá para seu repositório no GitHub
2. Clique em **Settings** (Configurações)
3. No menu lateral, clique em **Secrets and variables** → **Actions**

### 2. Adicionar Secrets Obrigatórios

#### `AWS_ACCESS_KEY_ID`
- **Nome**: `AWS_ACCESS_KEY_ID`
- **Valor**: Sua AWS Access Key ID
- **Exemplo**: `AKIAIOSFODNN7EXAMPLE`

#### `AWS_SECRET_ACCESS_KEY`
- **Nome**: `AWS_SECRET_ACCESS_KEY`
- **Valor**: Sua AWS Secret Access Key
- **Exemplo**: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`

### 3. Configurar Backend S3 (Obrigatório)

Edite o arquivo `backend.tf` com suas configurações:

```hcl
terraform {
  backend "s3" {
    bucket = "wordpress-terraform-state-[SEU-NOME]"
    key    = "infra-wordpress/terraform.tfstate"
    region = "us-east-1"
    
    # Opcional: DynamoDB para lock
    # dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

## 🚀 Como Executar

### 1. Deploy Automático (Push para main)
```bash
git add .
git commit -m "Deploy WordPress infrastructure"
git push origin main
```

### 2. Deploy Manual
1. Vá para **Actions** no GitHub
2. Selecione **🚀 WordPress Terraform CI/CD Pipeline**
3. Clique em **Run workflow**
4. Selecione:
   - **Action**: `apply`
   - **Environment**: `prod`
5. Clique em **Run workflow**

### 3. Destruir Infraestrutura
1. Vá para **Actions** no GitHub
2. Selecione **🗑️ WordPress Terraform Destroy**
3. Clique em **Run workflow**
4. Digite **DESTROY** na confirmação
5. Selecione o ambiente
6. Clique em **Run workflow**

## 📊 Monitoramento

### Logs do Pipeline
- Acesse **Actions** → Seu workflow → Logs detalhados
- Cada step tem logs específicos

### Outputs do Terraform
Após deploy bem-sucedido, você verá:
```
WordPress URL: http://wordpress-alb-[ID].us-east-1.elb.amazonaws.com
WordPress Admin: http://wordpress-alb-[ID].us-east-1.elb.amazonaws.com/wp-admin
WordPress Install: http://wordpress-alb-[ID].us-east-1.elb.amazonaws.com/wp-admin/install.php
```

## 🚨 Troubleshooting

### Erro: "Context access might be invalid"
- **Causa**: Secrets não configurados
- **Solução**: Verificar se `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` estão configurados

### Erro: "Backend configuration changed"
- **Causa**: Bucket S3 não existe ou não tem acesso
- **Solução**: Criar bucket S3 ou verificar permissões

### Erro: "ALB Health Check Failed"
- **Causa**: WordPress demora para inicializar
- **Solução**: Aguardar 10-15 minutos após deploy

### Erro: "IAM permissions"
- **Causa**: Usuário AWS sem permissões suficientes
- **Solução**: Adicionar permissões IAM necessárias

## 🔄 Fluxo de Trabalho

```mermaid
graph TD
    A[Push para main] --> B[Validate]
    B --> C[Plan]
    C --> D[Apply]
    D --> E[WordPress Deployed]
    
    F[Manual Trigger] --> G[Select Action]
    G --> H[Validate/Plan/Apply]
    H --> E
    
    I[Destroy Trigger] --> J[Type DESTROY]
    J --> K[Confirm Environment]
    K --> L[Infrastructure Destroyed]
```

## 🎯 Próximos Passos

1. **Configure os secrets** conforme instruções acima
2. **Edite o backend.tf** com seu bucket S3
3. **Faça commit e push** para ativar o pipeline
4. **Aguarde 10-15 minutos** para WordPress inicializar
5. **Acesse o WordPress** na URL fornecida nos outputs

---

📞 **Suporte**: Se encontrar problemas, verifique os logs no GitHub Actions e a documentação da AWS.
