output "master_public_ip" {
  value = module.compute.master_public_ip
}

output "worker_public_ips" {
  value = module.compute.worker_public_ips
}

output "master_private_ip" {
  value = module.compute.master_private_ip
}

output "worker_private_ips" {
  value = module.compute.worker_private_ips
}

output "db_endpoint" {
  value = module.database.db_endpoint
}
