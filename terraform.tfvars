# Configurações básicas
region      = "us-east-1"
environment = "Dev"

# Configurações EC2
ec2_instance_type = "t2.micro"
ec2_count         = 1
ec2_name          = "wordpress-instancia"
enable_ssm        = true   # Habilitar SSM Session Manager

# Configurações de rede
vpc_cidr                = "10.0.0.0/16"
public_subnet_cidr_a    = "10.0.1.0/24"
public_subnet_cidr_b    = "10.0.2.0/24"
private_subnet_cidr_a   = "10.0.3.0/24"
private_subnet_cidr_b   = "10.0.4.0/24"
availability_zone_a     = "us-east-1a"
availability_zone_b     = "us-east-1b"

# Configurações EBS
ebs_volume_size = 10
ebs_volume_type = "gp3"

# Configurações S3
s3_bucket_name              = "mfdemenezes-terraform-bucket"
s3_block_public_access      = true   # Manter bloqueado para segurança
s3_enable_bucket_policy     = true   # Habilitar política SSL only
s3_enable_versioning        = false  # Versionamento desabilitado
s3_enable_encryption        = true   # Criptografia habilitada





