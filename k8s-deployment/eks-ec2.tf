terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 6.4.0"
    }
  }
}
provider "aws" {
  region = "ap-south-1"
}

//Create VPC
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "eks_vpc"
  }
}

//Create Subnets
resource "aws_subnet" "eks_subnet_1a" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.1.0/24"  # Subnet range
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "eks_subnet-1a"
  }
}
resource "aws_subnet" "eks_subnet_1b" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.2.0/24"  # Subnet range
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "eks_subnet-1b"
  }
}
resource "aws_subnet" "eks_subnet_1c" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.3.0/24"  # Subnet range
  availability_zone = "ap-south-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "eks_subnet-1c"
  }
}

//Create InternetGateway
resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "eks_igw"
  }
}

//Create Routetable
resource "aws_route_table" "eks_routetable" {
  vpc_id = aws_vpc.eks_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }
  tags = {
    Name = "eks_routetable"
  }
}

//Associate subnet to routetable
resource "aws_route_table_association" "eks_rt_association_1a" {
  subnet_id      = aws_subnet.eks_subnet_1a.id
  route_table_id = aws_route_table.eks_routetable.id
}

resource "aws_route_table_association" "eks_rt_association_1b" {
  subnet_id      = aws_subnet.eks_subnet_1b.id
  route_table_id = aws_route_table.eks_routetable.id
}

resource "aws_route_table_association" "eks_rt_association_1c" {
  subnet_id      = aws_subnet.eks_subnet_1c.id
  route_table_id = aws_route_table.eks_routetable.id
}
//Create security group
resource "aws_security_group" "eks_security_group" {
  name        = "eks_security_group"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "eks_security_group"
  }
}

//Create EC2
resource "aws_instance" "my-ec2" {
  ami = "ami-09b0a86a2c84101e1"
  instance_type = "t2.micro"
  key_name = "mydemokey"
  subnet_id = aws_subnet.eks_subnet_1a.id
  vpc_security_group_ids = [aws_security_group.eks_security_group.id]
  tags = {
    Name = "eks_ec2"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.11.0" 

  cluster_name    = "my-cluster-eks"
  cluster_version = "1.31"

  cluster_endpoint_public_access = true

  vpc_id                   = aws_vpc.eks_vpc.id
  subnet_ids               = [aws_subnet.eks_subnet_1a.id, aws_subnet.eks_subnet_1b.id, aws_subnet.eks_subnet_1c.id]
  control_plane_subnet_ids = [aws_subnet.eks_subnet_1a.id, aws_subnet.eks_subnet_1b.id, aws_subnet.eks_subnet_1c.id]

  eks_managed_node_groups = {
    green = {
      min_size       = 1
      max_size       = 1
      desired_size   = 1
      instance_types = ["t3.medium"]
    }
  }
}