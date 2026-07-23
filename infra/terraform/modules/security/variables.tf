variable "project_name" {
  description = "Prefixo usado no nome dos recursos"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC onde os Security Groups serão criados"
  type        = string
}

variable "admin_cidr" {
  description = "CIDR (IP/32) autorizado a acessar SSH — nunca 0.0.0.0/0"
  type        = string
}
