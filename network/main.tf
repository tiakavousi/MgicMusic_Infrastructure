###############################
# VPC
###############################
resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.vpc_name}-${terraform.workspace}"
    "kubernetes.io/cluster/${var.eks_cluster_name}-${terraform.workspace}" = "shared"
    Environment = terraform.workspace
  }
}

data "aws_availability_zones" "all" { }

##################################
# INTERNET GATEWAY
##################################

/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name        = "ig-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

/* Elastic IP for NAT */
resource "aws_eip" "nat_eip" {
  vpc        = true
}

/* NAT */
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.pub_subnet[0].id
  depends_on    = [aws_internet_gateway.ig]
  tags = {
    Name        = "eks-nat-gw-${terraform.workspace}"
    Environment = terraform.workspace
  }
}
/* Routing table for private subnet */
resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name        = "eks-private-rt-${terraform.workspace}"
    Environment = terraform.workspace
  }
}
/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
  tags = {
    Name        = "eks-public-rt-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

# resource "aws_route" "public_internet_gateway" {
#   route_table_id         = aws_route_table.public.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = "${aws_internet_gateway.ig.id}"
# }

# resource "aws_route" "private_nat_gateway" {
#   route_table_id         = "${aws_route_table.private.id}"
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = "${aws_nat_gateway.nat.id}"
# }

/* Route table associations */
resource "aws_route_table_association" "public" {
  count = length(data.aws_availability_zones.all.names)

  subnet_id      = element(aws_subnet.pub_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.priv_subnet.*.id)
  subnet_id      = aws_subnet.priv_subnet[count.index].id
  route_table_id = aws_route_table.private.id
}

#####################################
# Public Subnets
#####################################
resource "aws_subnet" "pub_subnet" {
  count = length(data.aws_availability_zones.all.names)

  vpc_id     = aws_vpc.vpc.id
  cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, 6, count.index)
  availability_zone = data.aws_availability_zones.all.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${terraform.workspace}-public-subnet-${(count.index + 1)}"
    "kubernetes.io/cluster/${var.eks_cluster_name}-${terraform.workspace}" = "shared"
    "kubernetes.io/role/elb" = 1
    Environment = terraform.workspace
  }
}

###############################
# Private Subnets
###############################
resource "aws_subnet" "priv_subnet" {
  count = length(data.aws_availability_zones.all.names)

  vpc_id     = aws_vpc.vpc.id
  cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, 6, count.index + length(data.aws_availability_zones.all.names))
  availability_zone = data.aws_availability_zones.all.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${terraform.workspace}-private-subnet-${(count.index + 1)}"
    "kubernetes.io/cluster/${var.eks_cluster_name}-${terraform.workspace}" = "shared"
    "kubernetes.io/role/internal-elb" = 1
    Environment = terraform.workspace
  }
}
