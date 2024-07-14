# Configure the AWS provider
provider "aws" {
  region     = "us-east-1"
  access_key = "AKIA***********KGXUT7KY"
  secret_key = "AShA8Zb*********************+sinme0fdjlmz"
}

# Creating a VPC
resource "aws_vpc" "demo_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "JBuild-Server"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "demo_ig" {
  vpc_id = aws_vpc.demo_vpc.id
  tags = {
    Name = "JBuild-Server"
  }
}

# Setting up the route table
resource "aws_route_table" "demo_rt" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    # pointing to the internet
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_ig.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.demo_ig.id
  }
  tags = {
    Name = "JBuild-Server"
  }
}

# Setting up the subnet
resource "aws_subnet" "demo_subnet" {
  vpc_id             = aws_vpc.demo_vpc.id
  cidr_block         = "10.0.1.0/24"
  availability_zone  = "us-east-1b"
  tags = {
    Name = "JBuild-Server"
  }
}

# Associating the subnet with the route table
resource "aws_route_table_association" "proj_rt_sub_assoc" {
  subnet_id      = aws_subnet.demo_subnet.id
  route_table_id = aws_route_table.demo_rt.id
}

# Creating a Security Group
resource "aws_security_group" "demo_sg" {
  name        = "JBuild-Server"
  description = "Enable all traffic for the project"
  vpc_id      = aws_vpc.demo_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

  tags = {
    Name = "JBuild-Server"
  }
}

# Creating a new network interface
resource "aws_network_interface" "demo_ni" {
  subnet_id       = aws_subnet.demo_subnet.id
  private_ips     = ["10.0.1.10"]
  security_groups = [aws_security_group.demo_sg.id]
}

# Creating an Ubuntu EC2 instance
resource "aws_instance" "test_server" {
  ami           = "ami-0a0e5d9c7acc336f1"
  instance_type = "t2.micro"
  key_name      = "awsec2"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.demo_ni.id
  }
  
  user_data = <<-EOF
  #!/bin/bash
  sudo apt-get update -y
  EOF

  tags = {
    Name = "JBuild-Server"
  }
}

# Attaching an elastic IP to the network interface
resource "aws_eip" "demo_eip" {
  network_interface         = aws_network_interface.demo_ni.id
  associate_with_private_ip = "10.0.1.10"

  depends_on = [aws_instance.test_server]

  tags = {
    Name = "JBuild-Server"
  }
}
