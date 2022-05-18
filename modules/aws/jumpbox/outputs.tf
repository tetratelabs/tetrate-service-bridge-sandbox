output "public_ip" {
  value = aws_instance.jumpbox.public_ip
}

output "pkey" {
  value = tls_private_key.generated.private_key_pem
}
