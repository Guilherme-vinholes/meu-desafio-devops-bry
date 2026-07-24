# Tráfego público do site: 80/443 abertos para o mundo (Nginx Ingress do cluster escuta aqui).
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web"
  description = "HTTP/HTTPS publicos para o Ingress"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# SSH restrito ao IP do administrador — nunca exposto publicamente (0.0.0.0/0).
resource "aws_security_group" "ssh" {
  name        = "${var.project_name}-ssh"
  description = "SSH restrito ao IP do administrador"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH (admin only)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ssh-sg"
  }
}

# Comunicação interna do cluster K3s (API server, kubelet, overlay de rede Flannel).
# Auto-referenciado: só instâncias que também têm este SG conseguem falar nessas portas
# entre si — nunca exposto publicamente, mesmo por engano.
resource "aws_security_group" "cluster_internal" {
  name        = "${var.project_name}-cluster-internal"
  description = "Comunicacao interna do cluster K3s (nunca publica)"
  vpc_id      = var.vpc_id

  ingress {
    description = "K3s API server (master e workers)"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Kubelet metrics/API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Flannel VXLAN overlay"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-cluster-internal-sg"
  }
}

# RDS: só aceita conexão de instâncias com o SG de cluster interno — nunca publico.
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db"
  description = "Postgres acessivel somente pelo cluster K3s"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres a partir do cluster"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster_internal.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}
