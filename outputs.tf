# outputs.tf

output "ec2_public_ip" {
  description = "IP Pública de la instancia EC2"
  value       = aws_instance.web_server.public_ip
}

output "s3_bucket_name" {
  description = "Nombre (único) del bucket S3 de logs"
  value       = aws_s3_bucket.logs_bucket.bucket
}

output "ebs_snapshot_id" {
  description = "ID del Snapshot de EBS creado"
  value       = aws_ebs_snapshot.data_snapshot.id
}

output "efs_file_system_id" {
  description = "ID del sistema de archivos EFS"
  value       = aws_efs_file_system.shared_fs.id
}
