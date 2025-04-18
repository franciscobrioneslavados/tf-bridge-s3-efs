# Security Group para la instancia EC2
resource "aws_security_group" "ec2_sg" {
  name        = "${var.environment}-${var.project}-ec2-sg"
  description = "Security group for EC2 instance to access EFS"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["201.223.97.240/32"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["201.223.97.240/32"]
  }

  # Acceso saliente a Internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-${var.project}-ec2-sg"
  }
}

# Crear el par de claves
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Registrar el par de claves en AWS
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.environment}-${var.project}-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}


# Guardar la clave privada localmente
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/${var.environment}-${var.project}-key.pem"
  file_permission = "0400" # Permisos correctos para una clave SSH privada
}

# IAM role para EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-${var.project}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Adjuntar política AmazonSSMManagedInstanceCore para gestión sin SSH
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Política para acceder a S3 y EFS
resource "aws_iam_policy" "ec2_s3_efs_policy" {
  name        = "${var.environment}-${var.project}-ec2-s3-efs-policy"
  description = "Permite a EC2 acceder a S3 y EFS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite"
        ]
        Resource = aws_efs_file_system.main.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3_efs_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_s3_efs_policy.arn
}

# Perfil de instancia para EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-${var.project}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Script de inicio para instalar NFS y montar el EFS
locals {
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    
    # Instalar herramientas de NFS
    yum install -y amazon-efs-utils
    
    # Crear punto de montaje
    mkdir -p /mnt/efs
    
    # Montar el EFS
    mount -t efs -o tls ${aws_efs_file_system.main.id}:/ /mnt/efs
    
    # Configurar para que se monte automáticamente al reiniciar
    echo "${aws_efs_file_system.main.id}:/ /mnt/efs efs defaults,tls 0 0" >> /etc/fstab
    
    # Instalar herramientas AWS CLI
    yum install -y aws-cli
  EOF
}

# EC2 Instance
resource "aws_instance" "ec2" {
  ami                         = "ami-0e449927258d45bc4" # Amazon Linux 2
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  user_data                   = local.user_data
  key_name                    = aws_key_pair.ec2_key_pair.key_name
  tags = {
    Name = "${var.environment}-${var.project}-ec2"
  }
}