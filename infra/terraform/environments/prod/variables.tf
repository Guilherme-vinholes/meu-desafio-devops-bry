variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "bry-desafio"
}

variable "admin_cidr" {
  description = "Seu IP publico em formato CIDR (ex: 203.0.113.10/32) — unico autorizado a acessar SSH"
  type        = string
}

variable "ssh_public_key" {
  description = "Conteudo da sua chave publica SSH (cat ~/.ssh/id_ed25519.pub)"
  type        = string
}

variable "master_instance_type" {
  type    = string
  default = "t3.small"
}

variable "worker_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "worker_count" {
  type    = number
  default = 2
}

variable "db_name" {
  type    = string
  default = "signatures"
}

variable "db_username" {
  type    = string
  default = "signatures"
}

variable "db_password" {
  type      = string
  sensitive = true
}
