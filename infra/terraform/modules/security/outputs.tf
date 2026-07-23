output "web_sg_id" {
  value = aws_security_group.web.id
}

output "ssh_sg_id" {
  value = aws_security_group.ssh.id
}

output "cluster_internal_sg_id" {
  value = aws_security_group.cluster_internal.id
}

output "db_sg_id" {
  value = aws_security_group.db.id
}
