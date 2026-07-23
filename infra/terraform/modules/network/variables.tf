variable "project_name" {
  description = "Prefixo usado no nome dos recursos"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs das subnets públicas (uma por AZ) — hospedam o cluster K3s"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs das subnets privadas (uma por AZ) — hospedam o RDS"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}
