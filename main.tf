# The following terraform builds this AWS VPC example - https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario2.html
# 1. Builds an AWS VPC
# 2. Builds 2 Subnets (1 public/1 private)
# 3. Builds Internet Gateway (igw) & "attach" to VPC - So that instances in public subnet can send requests to the internet
# 4. Elastic IP + attach to NAT Gateway (ngw) - So that instances in private subnet can send requests to the internet
# 5. Public Route table & Route table association of public subnet to igw
# 6. Private Route table & Route table association of private subnet to ngw

terraform {
  required_version = "0.11.13"
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "PhilsTestVPC" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "Phils Terraform VPC"
  }
}

# Public Subnet

resource "aws_subnet" "PublicSub" {
  cidr_block = "10.0.0.0/24"
  vpc_id     = "${aws_vpc.PhilsTestVPC.id}"

  tags {
    Name = "Phils Terraform Public Subnet"
  }
}

# Private Subnet

resource "aws_subnet" "PrivateSub" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = "${aws_vpc.PhilsTestVPC.id}"

  tags {
    Name = "Phils Terraform Private Subnet"
  }
}

# VPC Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.PhilsTestVPC.id}"

  tags {
    Name = "Phils Terraform IGW"
  }
}

# NAT Gateway + EIP

resource "aws_eip" "NAT_EIP" {
  vpc = true

  tags {
    Name = "Phils Terraform NAT EIP"
  }
}

resource "aws_nat_gateway" "NATGW" {
  allocation_id = "${aws_eip.NAT_EIP.id}"
  subnet_id     = "${aws_subnet.PublicSub.id}"
  depends_on    = ["aws_internet_gateway.igw"]

  tags {
    Name = "Phils Terraform NATGW"
  }
}

# Route Table - PUBLIC

resource "aws_route_table" "Public" {
  vpc_id = "${aws_vpc.PhilsTestVPC.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags {
    Name = "Phils Terraform Public Route Table"
  }
}

resource "aws_route_table_association" "PublicTable" {
  subnet_id      = "${aws_subnet.PublicSub.id}"
  route_table_id = "${aws_route_table.Public.id}"
}

# Route Table - PRIVATE

resource "aws_route_table" "Private" {
  vpc_id = "${aws_vpc.PhilsTestVPC.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.NATGW.id}"
  }

  tags {
    Name = "Phils Terraform Private Route Table"
  }
}

resource "aws_route_table_association" "MainRouteTable" {
  subnet_id      = "${aws_subnet.PrivateSub.id}"
  route_table_id = "${aws_route_table.Private.id}"
}
