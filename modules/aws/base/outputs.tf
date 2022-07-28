output "vpc_id" {
  value = aws_vpc.tsb.id
}

output "vpc_subnets" {
  value = aws_subnet.tsb.*.id
}

output "registry" {
  value = aws_ecr_repository.tsb.repository_url
}

output "registry_id" {
  value = aws_ecr_repository.tsb.registry_id
}

output "cidr" {
  value = var.cidr
}

