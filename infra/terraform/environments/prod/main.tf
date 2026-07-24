module "network" {
  source = "../../modules/network"

  project_name = var.project_name
}

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  vpc_id       = module.network.vpc_id
  admin_cidr   = var.admin_cidr
}

module "compute" {
  source = "../../modules/compute"

  project_name       = var.project_name
  public_subnet_ids  = module.network.public_subnet_ids
  security_group_ids = [
    module.security.web_sg_id,
    module.security.ssh_sg_id,
    module.security.cluster_internal_sg_id,
  ]
  ssh_public_key       = var.ssh_public_key
  master_instance_type = var.master_instance_type
  worker_instance_type = var.worker_instance_type
  worker_count         = var.worker_count
}

module "database" {
  source = "../../modules/database"

  project_name         = var.project_name
  private_subnet_ids   = module.network.private_subnet_ids
  db_security_group_id = module.security.db_sg_id
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
}
