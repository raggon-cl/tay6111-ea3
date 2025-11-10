# main.tf

# --- Configuración del Provider ---
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- REQUISITO A: INFRAESTRUCTURA BASE (Red y Cómputo) ---

# A.1 VPC y Redes [cite: 35]
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "vpc-datacore"
  }
}

# Subnets Públicas (una en cada AZ) [cite: 39]
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true # Importante para subnets públicas

  tags = {
    Name = "subnet-public-${count.index + 1}"
  }
}

# Subnets Privadas (una en cada AZ) [cite: 41]
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "subnet-private-${count.index + 1}"
  }
}

# Internet Gateway y Ruteo [cite: 42]
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "igw-datacore"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "rt-public"
  }
}

# Asociación de la tabla de rutas públicas a las subnets públicas
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

/*
# A.2 Seguridad (Security Groups) [cite: 43]
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Permite tráfico SSH y HTTP"
  vpc_id      = aws_vpc.main.id

  # Acceso SSH (Puerto 22) [cite: 44]
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Acceso HTTP (Puerto 80) [cite: 44]
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permite todo el tráfico de salida
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-web"
  }
}

resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Permite tráfico NFS desde el SG web"
  vpc_id      = aws_vpc.main.id

  # Acceso NFS (Puerto 2049) SOLO desde el SG web [cite: 46]
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id] # Referencia cruzada
  }

  # Permite todo el tráfico de salida
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-efs"
  }
}

# A.3 Cómputo (Instancia EC2) [cite: 47]
# Busca la AMI más reciente de Amazon Linux 2
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux_2.id # AMI de Amazon Linux 2 [cite: 49]
  instance_type = var.instance_type              # t2.micro [cite: 49]

  # Despliega en la primera subnet pública [cite: 49]
  subnet_id = aws_subnet.public[0].id

  # Asocia el Security Group de Web [cite: 49]
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "servidor-web-datacore"
  }
}

# --- REQUISITO B: Amazon EBS [cite: 54] ---

# B.1 Volumen de Datos [cite: 56]
resource "aws_ebs_volume" "data_volume" {
  # El volumen debe estar en la misma AZ que la instancia
  availability_zone = aws_instance.web_server.availability_zone
  size              = var.ebs_volume_size_gb # 8 GiB [cite: 56]
  type              = "gp3"                  # gp3 [cite: 56]

  tags = {
    Name = "volumen-datos-app"
  }
}

# B.2 Asociación del volumen a la instancia [cite: 57]
resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/sdh" # Nombre de dispositivo sugerido
  volume_id   = aws_ebs_volume.data_volume.id
  instance_id = aws_instance.web_server.id
}

# B.3 Respaldo (Snapshot) [cite: 58]
resource "aws_ebs_snapshot" "data_snapshot" {
  # Depende de que el volumen esté adjunto
  depends_on = [aws_volume_attachment.ebs_attach]

  volume_id = aws_ebs_volume.data_volume.id

  tags = {
    Name = "snapshot-app-prod" # Etiquetado requerido [cite: 59]
  }
}

# --- REQUISITO C: Amazon S3 [cite: 60] ---

# Helper para asegurar un nombre de bucket único [cite: 62]
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# C.1 Bucket S3 [cite: 62]
resource "aws_s3_bucket" "logs_bucket" {
  bucket = "datacore-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "Bucket de Logs DataCore"
  }
}

# C.2 Política de Ciclo de Vida [cite: 63]
resource "aws_s3_bucket_lifecycle_configuration" "logs_lifecycle" {
  bucket = aws_s3_bucket.logs_bucket.id

  rule {
    id     = "transicion-ia-y-glacier"
    status = "Enabled"

    # Regla 1: Transición a STANDARD_IA después de 30 días [cite: 66]
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Regla 2: Transición a GLACIER después de 120 días totales [cite: 67]
    # (El PDF dice 90 días *después* de IA, sumando 120 días desde la creación)
    transition {
      days          = 120
      storage_class = "GLACIER"
    }
  }
}

# --- REQUISITO D: Amazon EFS [cite: 68] ---

# D.1 Sistema de Archivos EFS [cite: 70]
resource "aws_efs_file_system" "shared_fs" {
  tags = {
    Name = "EFS-Compartido-DataCore"
  }
}

# D.2 Destinos de Montaje (Mount Targets) [cite: 71]
resource "aws_efs_mount_target" "main" {
  count = length(aws_subnet.private) # 2 Mount Targets, uno por subnet privada [cite: 71]

  file_system_id = aws_efs_file_system.shared_fs.id
  subnet_id      = aws_subnet.private[count.index].id

  # Asocia el Security Group de EFS [cite: 72]
  security_groups = [aws_security_group.efs_sg.id]
}
*/