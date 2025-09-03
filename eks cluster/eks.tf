terraform {
  required_providers {
    aws = {
        source = "hoshicorp/aws"
        version = "~> 5.0"
    }
  }
}
provider "aws" {
    region = "ap-south-1"
  
}
//creating vpc
resource "aws_vpc" "eks-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "eks-vpc"
    }
  
}
//creating subnet

resource "aws_subnet" "eks-subnet-1a" {
    vpc_id = aws_vpc.eks_vpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true

    tags = {
      Name = "eks-subnet-1a"
    }
}
resource "aws_subnet" "eks-subnet-1b" {
    vpc_id = aws_vpc.eks_vpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = true

    tags = {
      Name = "eks-subnet-1b"
    }
  
}
resource "aws_subnet" "eks-subnet-1c" {
    vpc_id = aws_vpc.eks-vpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "ap-south-1c"
    map_public_ip_on_launch = true

    tags = {
      Names = "eks-subnet-1c"
    }
  
}
//create internet gateway
resource "aws_internet_gateway" "eks-igw" {
vpc_id = aws_vpc.eks-vpc.id

tags = {
  Name = "eks-igw"
}
  
}
//creating routetable
resource "aws_route_table" "eks-route" {
vpc_id = aws_vpc.eks-vpc.id
route = {
    cidr_block = "0.0.0.0/0"
    gateway_id =aws_internet_gateway.eks-igw.id
}

}
//associate subnet groups to route table

resource "aws_route_table_association" "eks-rt-association-1a" {
    subnet_id = aws_subnet.eks-subnet-1a.id
    route_table_id = aws_route_table.eks-route.id
  
}
resource "aws_route_table_association" "eks-rt-association-1b" {
    subnet_id = aws_subnet.eks-subnet-1b.id
    route_table_id = aws_route_table.eks-route.id
  
}
resource "aws_route_table_association" "neks-rt-association-1c" {
    subnet_id = aws_subnet.eks-subnet-1c.id
    route_table_id = aws_route_table.eks-route.id
  
}
//create a security group
resource "aws_security_group" "eks-security-group" {
    name = "eks-security-group"
    vpc_id = aws_vpc.eks-vpc.ip
 ingress = {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_block = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

    from_port = 80
    to_port =80
    protocol = "tcp"
    cidr_block = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
 }
 
 egress = {
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_block = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
 }
 tags = {
   Name = "eks-security-group"
 }
  
}
//create ec2 instance
resource "aws_instance" "eks-ec2" {
    ami = "ami-09b0a86a2c84101e1"
    instance_type = "t2 micro"
    key_name = "mykeypair"
    vpc_security_group_ids = [aws_security_group.eks-security-group.id]
    subnet_id = aws_subnet.eks-subnet-1a
    tags = {
      Name = "eks-ec2"
      
    }  
}

//create eks
module "eks" {
    source                         = "terraform-aws-modules/eks/aws"
    version                        = "~>19.0"
    cluster_name                   = "my-eks-cluster"
    cluster_version                = "1.31"
    cluster_endpoint_public_access = true
    vpc_id                         = aws_vpc.eks-vpc
    subnet_ids                     = [aws_subnet.eks-subnet-1a.id, aws_subnet.eks-subnet-1b.id, aws_subnet.eks-subnet-1c.id]
    control_plane_subnet_ids       = [aws_subnet.eks-subnet-1a.id, aws_subnet.eks-subnet-1b.id, aws_subnet.eks-subnet-1c.id]
    eks_managed_node_groups        = {
        my-node = {
            min_size      = 1
            max_size      = 1
            desired_size  = 1
            instance_type = ["t3.medium"]
        }
    }
  
}

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 19.0"

#   cluster_name    = "my-cluster-eks"
#   cluster_version = "1.31"

#   cluster_endpoint_public_access = true

#   vpc_id                   = aws_vpc.eks_vpc.id
#   subnet_ids               = [aws_subnet.eks_subnet_1a.id, aws_subnet.eks_subnet_1b.id, aws_subnet.eks_subnet_1c.id]
#   control_plane_subnet_ids = [aws_subnet.eks_subnet_1a.id, aws_subnet.eks_subnet_1b.id, aws_subnet.eks_subnet_1c.id]

#   eks_managed_node_groups = {
#     green = {
#       min_size       = 1
#       max_size       = 1
#       desired_size   = 1
#       instance_types = ["t3.medium"]
#     }
#   }
# }