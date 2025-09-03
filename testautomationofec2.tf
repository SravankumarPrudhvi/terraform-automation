provider "aws" {
  region = "ap-south-1"
  
}



resource "aws_vpc" "vpc-cicd" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc-testcicd"
    
  }
  
}

resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.vpc-cicd.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
}

resource "aws_subnet" "subnet-2" {
  vpc_id = aws_vpc.vpc-cicd.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
  
}

resource "aws_security_group" "security-cicd" {
  name = "security-cicd"
  description = "allow SSH and HTTP "
  vpc_id = aws_vpc.vpc-cicd.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   
   tags = {
     Name = "security-cicd"
   }
}

resource "aws_instance" "CICD" {
  ami = "ami-09b0a86a2c84101e1"
  instance_type = "t2.micro"
  key_name = "mykeypair-1"
  vpc_security_group_ids = aws_security_group.security-cicd
  subnet_id = aws_subnet.subnet-1
  tags = {
    Name = "CI/CD"
  }
}
