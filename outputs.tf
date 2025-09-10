# Outputs de rede
output "vpc_id" {
  description = "ID da VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs das Subnets Públicas"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs das Subnets Privadas"
  value       = module.network.private_subnet_ids
}

output "nat_gateway_id" {
  description = "ID do NAT Gateway"
  value       = module.network.nat_gateway_id
}

# Outputs do ALB
output "alb_dns_name" {
  description = "DNS name do Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN do Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_url" {
  description = "URL completa do ALB para acessar WordPress"
  value       = "http://${aws_lb.main.dns_name}"
}

output "alb_security_group_id" {
  description = "ID do Security Group do ALB"
  value       = aws_security_group.alb.id
}

# URLs de Acesso ao WordPress
output "wordpress_access_urls" {
  description = "URLs de acesso ao WordPress"
  value = {
    alb_http         = "http://${aws_lb.main.dns_name}"
    primary_url      = "http://${aws_lb.main.dns_name}"
    install_url      = "http://${aws_lb.main.dns_name}/wp-admin/install.php"
  }
}

# Outputs de segurança
output "security_group_ids" {
  description = "IDs dos Security Groups"
  value       = [module.security_group.security_group_id, aws_security_group.alb.id]
}

# # Outputs do CloudFront (desabilitado)
# output "cloudfront_domain_name" {
#   description = "Domain name do CloudFront distribution"
#   value       = module.cloudfront.cloudfront_domain_name
# }

# output "cloudfront_url" {
#   description = "URL completa do CloudFront (RECOMENDADA)"
#   value       = module.cloudfront.cloudfront_url
# }

# output "cloudfront_distribution_id" {
#   description = "ID do CloudFront distribution"
#   value       = module.cloudfront.cloudfront_distribution_id
# }

# output "alb_security_group_id" {
#   description = "ID do Security Group do ALB"
#   value       = module.alb.alb_security_group_id
# }

# Outputs do S3
output "s3_bucket_name" {
  description = "Nome do bucket S3"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN do bucket S3"
  value       = module.s3.bucket_arn
}

# Outputs das instâncias EC2
output "instance_ids" {
  description = "IDs das instâncias EC2"
  value       = module.ec2.instance_ids
}

output "instance_private_ips" {
  description = "IPs privados das instâncias EC2"
  value       = module.ec2.instance_private_ips
}

# Outputs de acesso
# output "n8n_access_urls" {
#   description = "URLs de acesso ao N8N"
#   value = {
#     cloudfront_https = module.cloudfront.cloudfront_url
#     alb_http         = "http://${module.alb.alb_dns_name}"
#   }
# }

# Outputs de acesso temporário (EC2 privada)
output "wordpress_access_info" {
  description = "Informações de acesso ao WordPress (EC2 em subnet privada)"
  value = {
    ec2_private_ips = module.ec2.instance_private_ips
    access_method   = "Use AWS Session Manager to connect to EC2 instances"
    vpc_id          = module.network.vpc_id
    private_subnets = module.network.private_subnet_ids
    wordpress_install = "Access /wp-admin/install.php to setup WordPress"
  }
}

# Outputs gerais
output "region" {
  description = "Região AWS"
  value       = var.region
}

output "environment" {
  description = "Ambiente"
  value       = var.environment
}

output "project_name" {
  description = "Nome do projeto"
  value       = var.ec2_name
}

# Compatibilidade com versão anterior
output "subnet_id" {
  description = "ID da Subnet (compatibilidade - subnet privada A)"
  value       = module.network.private_subnet_a_id
}

output "security_group_id" {
  description = "ID do Security Group principal (compatibilidade)"
  value       = module.security_group.security_group_id
}
