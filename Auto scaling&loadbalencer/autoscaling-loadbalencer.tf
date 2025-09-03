terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"aws s3 
        version = "~> 5.0"
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
  ingress{
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "eks_security_group"
  }
}

//  Create an IAM Role
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      },
    ]
  })
}

//Attach Policies to the IAM Role
resource "aws_iam_policy_attachment" "ec2_role_policy" {
  name       = "ec2-role-policy-attachment"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"     //(AmazonS3ReadOnlyAccess s3readonly policy)  # Example policy (modify as needed)
}

//Create an Instance Profile (required for EC2)
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}



//Create EC2 Instance and Attach the IAM Role
resource "aws_instance" "my-ec2" {
  ami = "ami-09b0a86a2c84101e1"
  instance_type = "t2.micro"
  key_name = "mykeypair"
  subnet_id = aws_subnet.eks_subnet_1a.id
  vpc_security_group_ids = [aws_security_group.eks_security_group.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  tags = {
    Name = "eks_ec2"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.31"

  cluster_endpoint_public_access = true

  vpc_id                   = aws_vpc.eks_vpc.id
  subnet_ids               = [aws_subnet.eks_subnet_1a.id, aws_subnet.eks_subnet_1b.id, aws_subnet.eks_subnet_1c.id]
  control_plane_subnet_ids = [aws_subnet.eks_subnet_1a.id, aws_subnet.eks_subnet_1b.id, aws_subnet.eks_subnet_1c.id]

  eks_managed_node_groups = {
    my-node = {
      min_size       = 1
      max_size       = 1
      desired_size   = 1
      instance_types = ["t3.medium"]
    }
  }
}

//Creating autyoscalling groups
resource "aws_placement_group" "test" {
  name     = "test"
  strategy = "cluster"
}

resource "aws_autoscaling_group" "bar" {
  name                      = "foobar3-terraform-test"
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 4
  force_delete              = true
  placement_group           = aws_placement_group.test.id
  launch_configuration      = aws_launch_configuration.foobar.name
  vpc_zone_identifier       = [aws_subnet.example1.id, aws_subnet.example2.id]

  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 120
  }

  initial_lifecycle_hook {
    name                 = "foobar"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"

    notification_metadata = jsonencode({
      foo = "bar"
    })

    notification_target_arn = "arn:aws:sqs:us-east-1:444455556666:queue1*"
    role_arn                = "arn:aws:iam::123456789012:role/S3Access"
  }

  tag {
    key                 = "foo"
    value               = "bar"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  tag {
    key                 = "lorem"
    value               = "ipsum"
    propagate_at_launch = false
  }
}

//creating a clasic Load Balencer
resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "classic"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "test-lb"
    enabled = true
  }

  tags = {
    Environment = "production"
  }
}