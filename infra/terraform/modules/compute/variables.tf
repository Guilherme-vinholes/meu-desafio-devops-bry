variable "project_name" {
  type = string
}

variable "public_subnet_ids" {
  description = "Subnets publicas onde as instancias EC2 do cluster ficam"
  type        = list(string)
}

variable "security_group_ids" {
  description = "SGs aplicados a todas as instancias do cluster (web + ssh + cluster_internal)"
  type        = list(string)
}

variable "ssh_public_key" {
  description = "Conteudo da chave publica SSH (ex: cat ~/.ssh/id_ed25519.pub) usada para acessar as instancias"
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

variable "root_volume_size_gb" {
  type    = number
  default = 20
}
