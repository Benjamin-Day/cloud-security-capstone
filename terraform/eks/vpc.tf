resource "aws_vpc" "main" {
  cidr_block = "10.2.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.env}-main"
  }

  # checkov:skip=CKV2_AWS_11: "Ensure VPC flow logging is enabled in all VPCs"
  # This is extremely cost prohibitive.
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
  ingress = []
  egress  = []
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.env}-igw"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${local.env}-nat"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_zone_1.id

  depends_on = [aws_eip.nat]

  tags = {
    Name = "${local.env}-nat"
  }
}


resource "aws_subnet" "private_zone_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.2.0.0/19"
  availability_zone = local.zone_1

  tags = {
    Name                              = "${local.env}-private-${local.zone_1}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private_zone_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.2.32.0/19"
  availability_zone = local.zone_2

  tags = {
    Name                              = "${local.env}-private-${local.zone_2}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "public_zone_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.2.64.0/19"
  availability_zone       = local.zone_1
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${local.env}-public-${local.zone_1}"
    "kubernetes.io/role/elb" = "1"
  }
  # checkov:skip=CKV_AWS_130: "Ensure VPC subnets do not assign public IP by default"
  # Assigning public IPs by default is required for nat gateway and alb. 
  # We are not deploying any other resources here.
}

resource "aws_subnet" "public_zone_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.2.128.0/19"
  availability_zone       = local.zone_2
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${local.env}-public-${local.zone_2}"
    "kubernetes.io/role/elb" = "1"
  }

  # checkov:skip=CKV_AWS_130: "Ensure VPC subnets do not assign public IP by default"
  # Assigning public IPs by default is required for nat gateway and alb. 
  # We are not deploying any other resources here.
}