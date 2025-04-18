output "ssh_key_path" {
  description = "Ruta al archivo de clave privada SSH"
  value       = local_file.private_key.filename
}

output "ec2_public_ip" {
  description = "IP pública de la instancia EC2"
  value       = aws_instance.ec2.public_ip
}

output "ec2_connect_command" {
  description = "Comando para conectarse a la instancia EC2"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.ec2.public_ip}"
}

output "ec2_ping_command" {
  description = "Comando para hacer ping a la instancia EC2"
  value       = "ping ${aws_instance.ec2.public_ip}"
}

output "ec2_check_efs_command" {
  description = "Comando para verificar el contenido del EFS en la instancia EC2"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.ec2.public_ip} 'ls -la /mnt/efs/lambda'"
}

output "ec2_monitor_lambda_file_command" {
  description = "Comando para monitorear continuamente los archivos que llegan al EFS"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.ec2.public_ip} 'watch -n 2 ls -la /mnt/efs/lambda'"
}

output "s3_upload_test_file_command" {
  description = "Comando para subir un archivo de prueba a S3"
  value       = "echo 'Este es un archivo de prueba' > test_file.txt && aws s3 cp test_file.txt s3://${aws_s3_bucket.main.id}/test/test_file.txt"
}