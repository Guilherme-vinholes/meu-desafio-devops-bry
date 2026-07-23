variable "project_name" {
  type = string
}

variable "private_subnet_ids" {
  description = "Subnets privadas (>=2 AZs) para o DB subnet group"
  type        = list(string)
}

variable "db_security_group_id" {
  type = string
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
  description = "Senha do master user do RDS — fornecida via tfvars (nao commitado) ou variavel de ambiente TF_VAR_db_password"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "allocated_storage_gb" {
  type    = number
  default = 20
}

variable "engine_version" {
  type    = string
  default = "16"
}
