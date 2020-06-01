// Network Routing Rules & Gateaways defined here

//Resources:
// VPC + public & private subnets
// availability zones
data "aws_availability_zones" "zones" {}

// vpc
resource "aws_vpc" "main" {
  cidr_block           = var.IP_RANGE
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.PROJECT}-vpc"
    Env  = var.ENV
  }
}

// -1 -> for now restricting to 2 az's,
locals {
  zones_count = length(data.aws_availability_zones.zones.names) - 1
}

// private subnet
resource "aws_subnet" "private" {
  count                   = local.zones_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.IP_RANGE, 8, local.zones_count + count.index)
  availability_zone       = element(data.aws_availability_zones.zones.names, count.index)
  tags = {
    Name = "${var.PROJECT}-private-subnet"
    Env  = var.ENV
  }
}

// public subnets
resource "aws_subnet" "public" {
  count                   = local.zones_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.IP_RANGE, 8, count.index)
  availability_zone       = element(data.aws_availability_zones.zones.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.PROJECT}-public-subnet-${count.index}}"
    Env  = var.ENV
  }
}
// Extra public subnet for alb (Making it cheaper -> NAT)


// IGW for the public subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = var.PROJECT
    Env  = var.ENV
  }
}

# Route the public subnet traffic through the IGW
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Create a NAT gateway with an EIP for each private subnet to get internet connectivity
resource "aws_eip" "gw" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = var.PROJECT
    Env  = var.ENV
  }
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.gw.id
  subnet_id     = element(aws_subnet.public.*.id, 0)
  depends_on    = [aws_internet_gateway.igw]
}

// Create a new route table for the private/public subnets
// And make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw.id
  }
  tags = {
    Name = var.PROJECT
    Env  = var.ENV
  }
}

resource "aws_route_table" "public" {
  count = length(data.aws_availability_zones.zones.names)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
    tags = {
    Name = var.PROJECT
    Env  = var.ENV
  }
}

// Explicitely associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private" {
  count          = local.zones_count
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_route_table_association" "public" {
  count          = local.zones_count
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = element(aws_route_table.public.*.id, count.index)
}

// db subnet group for RDS service
resource "aws_db_subnet_group" "postgres" {
  subnet_ids = aws_subnet.private.*.id
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.PROJECT}-${var.ENV}-redis"
  subnet_ids = aws_subnet.private.*.id
}

//// Internet Gateway for Airflow's Network
//resource "aws_internet_gateway" "airflow" {
//  vpc_id = aws_vpc.airflow.id
//
//  tags = {
//    Name = "${var.TAG}_public_subnet"
//  }
//}
//
//// Custom routing table
//resource "aws_route_table" "airflow" {
//  vpc_id = aws_vpc.airflow.id
//
//  route {
////The subnet will be reachable from everywhere !!!
//      cidr_block = "0.0.0.0/0"
////CRT will use this Internet Gateway to reach internet
//      gateway_id = aws_internet_gateway.airflow.id
//  }
//
//  tags = {
//    Name = "${var.TAG}_public_crt"
//  }
//}