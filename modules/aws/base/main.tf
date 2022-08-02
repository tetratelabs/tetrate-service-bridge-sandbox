resource "random_string" "random_prefix" {
  length  = 4
  special = false
  lower   = true
  upper   = false
  numeric = false
}
resource "aws_vpc" "tsb" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  tags = {
    Name  = "${var.name_prefix}-${random_string.random_prefix.result}_vpc"
    Owner = "${var.name_prefix}_tsb"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "tsb" {
  count                   = min(length(data.aws_availability_zones.available.names), var.min_az_count, var.max_az_count)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(var.cidr, 4, count.index)
  vpc_id                  = aws_vpc.tsb.id
  map_public_ip_on_launch = "true"
  tags = {
    Name  = "${var.name_prefix}-subnet-${data.aws_availability_zones.available.names[count.index]}"
    Owner = "${var.name_prefix}_tsb"
  }
}

resource "aws_internet_gateway" "tsb" {
  vpc_id = aws_vpc.tsb.id

  tags = {
    Name  = "${var.name_prefix}_igw"
    Owner = "${var.name_prefix}_tsb"
  }
}


resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.tsb.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tsb.id
  }

  tags = {
    Name  = "${var.name_prefix}_rt"
    Owner = "${var.name_prefix}_tsb"
  }
}


resource "aws_route_table_association" "rta" {
  count          = min(length(data.aws_availability_zones.available.names), var.min_az_count, var.max_az_count)
  subnet_id      = element(aws_subnet.tsb.*.id, count.index)
  route_table_id = aws_route_table.rt.id
}

resource "random_string" "random" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

resource "aws_ecr_repository" "tsb" {
  name                 = "tsbecr${var.name_prefix}${random_string.random.result}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

