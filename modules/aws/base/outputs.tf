output "vpc_id" {
  value = aws_vpc.tsb.id
}

output "vpc_subnets" {
  value = aws_subnet.tsb.*.id
}

output "registry" {
  value = aws_ecr_repository.tsb.repository_url
}

output "registry_name" {
  value = aws_ecr_repository.tsb.name
}

output "registry_id" {
  value = aws_ecr_repository.tsb.registry_id
}

output "registry_username" {
  value = data.aws_ecr_authorization_token.token.user_name
}

output "registry_password" {
  value = data.aws_ecr_authorization_token.token.password
}

output "cidr" {
  value = var.cidr
}

