provider "aws" {
  region = var.region
}


resource "aws_vpc" "module_vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags {
    Name = "demo-vpc"
  }
}

resource "aws_subnet" "module_public_subnet_1" {
  availability_zone = "${var.region}a"
  cidr_block = var.public_subnet_1_cidr
  vpc_id = "${aws_vpc.module_vpc.id}"
  tags {
    Name = "demo-subnet-1"
  }
}

resource "aws_subnet" "module_public_subnet_2" {
  availability_zone = "${var.region}b"
  cidr_block = var.public_subnet_2_cidr
  vpc_id = "${aws_vpc.module_vpc.id}"
  tags {
    Name = "demo-subnet-2"
  }
}

resource "aws_subnet" "module_public_subnet_3" {
  availability_zone = "${var.region}c"
  cidr_block = var.public_subnet_3_cidr
  vpc_id = "${aws_vpc.module_vpc.id}"
  tags {
    Name = "demo-subnet-3"
  }
}


resource "aws_subnet" "tf_module_private_subnet_1" {
  availability_zone = "${var.region}a"
  cidr_block = var.private_subnet_1_cidr
  vpc_id = "${aws_vpc.module_vpc.id}"
  tags {
    Name = "demo-subnet-3"
  }
}

resource "aws_subnet" "tf_module_private_subnet_2" {
  availability_zone = "${var.region}b"
  cidr_block = var.private_subnet_2_cidr
  vpc_id = "${aws_vpc.module_vpc.id}"
  tags {
    Name = "private-subnet-2"
  }
}

resource "aws_subnet" "tf_module_private_subnet_3" {
  availability_zone = "${var.region}c"
  cidr_block = var.private_subnet_3_cidr
  vpc_id = "${aws_vpc.module_vpc.id}"
  tags {
    Name = "private-subnet-3"
  }
}

resource "aws_route_table" "public_route_table" {

  vpc_id = aws_vpc.module_vpc.id
  tags {
    Name = "Public_route_table"
  }
}
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.module_vpc.id
  tags {
    Name = "private_rote_table"
  }
}

resource "aws_route_table_association" "public_subnet_1_association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id = aws_subnet.module_public_subnet_1.id
}
resource "aws_route_table_association" "public_subnet_3_association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id = aws_subnet.module_public_subnet_3.id
}

resource "aws_route_table_association" "public_subnet_3_association" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id = aws_subnet.module_public_subnet_3.id
}

resource "aws_route_table_association" "private_subnet_1_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id = aws_subnet.tf_module_private_subnet_1.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id = aws_subnet.tf_module_private_subnet_2.id
}

resource "aws_route_table_association" "private_subnet_3_association" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id = aws_subnet.tf_module_private_subnet_3.id
}

