resource "aws_vpc" "tsb" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  tags = merge(var.tags, {
    Name = "${var.name_prefix}_vpc"
  })
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "tsb" {
  count                   = min(length(data.aws_availability_zones.available.names), var.min_az_count, var.max_az_count)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(var.cidr, 4, count.index)
  vpc_id                  = aws_vpc.tsb.id
  map_public_ip_on_launch = "true"
  tags = merge(var.tags, {
    Name = "${var.name_prefix}_subnet_${data.aws_availability_zones.available.names[count.index]}"
  })
}

resource "aws_internet_gateway" "tsb" {
  vpc_id = aws_vpc.tsb.id
  tags = merge(var.tags, {
    Name = "${var.name_prefix}_igw"
  })
}


resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.tsb.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tsb.id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}_rt"
  })
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
  name                 = replace("tsbecr${var.name_prefix}${random_string.random.result}","-","")
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}_ecr"
  })
}

data "aws_ecr_authorization_token" "token" {
}
