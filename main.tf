# The following terraform builds this exact AWS VPC example - https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenario2.html
# 1. Builds an AWS VPC with cidr 10.0.0.0/16
# 2. Builds 2 Subnets (1 public/1 private)
# 3. Builds Internet Gateway (igw) & "attach" to VPC - So that instances in public subnet can send requests to the internet
# 4. Elastic IP + attach to NAT Gateway (ngw) - So that instances in private subnet can send requests to the internet
# 5. Public Route table & Route table association of public subnet to igw
# 6. Private Route table & Route table association of private subnet to ngw

terraform {
  required_version = "~> 0.11"
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_vpc" "vpcmain" {
  cidr_block = "10.0.0.0/16"
}

# Public Subnet

resource "aws_subnet" "PublicSub" {
  cidr_block = "10.0.0.0/24"
  vpc_id     = "${aws_vpc.vpcmain.id}"
}

# Private Subnet

resource "aws_subnet" "PrivateSub" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = "${aws_vpc.vpcmain.id}"
}

# VPC Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpcmain.id}"

}

# NAT Gateway + EIP

resource "aws_eip" "NAT_EIP" {
  vpc = true
}

resource "aws_nat_gateway" "NATGW" {
  allocation_id = "${aws_eip.NAT_EIP.id}"
  subnet_id     = "${aws_subnet.PublicSub.id}"
  depends_on    = ["aws_internet_gateway.igw"]
}

# Route Table - PUBLIC

resource "aws_route_table" "Public" {
  vpc_id = "${aws_vpc.vpcmain.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
}

resource "aws_route_table_association" "PublicTable" {
  subnet_id      = "${aws_subnet.PublicSub.id}"
  route_table_id = "${aws_route_table.Public.id}"
}

# Route Table - PRIVATE

resource "aws_route_table" "Private" {
  vpc_id = "${aws_vpc.vpcmain.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.NATGW.id}"
  }
}

resource "aws_route_table_association" "MainRouteTable" {
  subnet_id      = "${aws_subnet.PrivateSub.id}"
  route_table_id = "${aws_route_table.Private.id}"
}
