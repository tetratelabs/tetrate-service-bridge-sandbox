output "public_ip" {
  value = aws_instance.jumpbox.public_ip
}

output "jumpbox_iam_role_arn" {
  value = aws_iam_role.jumpbox_iam_role.arn
}

output "pkey" {
  value = tls_private_key.generated.private_key_pem
}
