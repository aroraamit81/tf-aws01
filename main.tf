terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
#test
# Configure the AWS Provider
provider "aws" {
  region     = "ap-southeast-2"
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_vpc" "tf-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "tf-vpc"
  }
}

resource "aws_subnet" "tf-subnet" {
  vpc_id     = aws_vpc.tf-vpc.id
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "tf-subnet"
  }
}

resource "aws_internet_gateway" "tf-gw" {
  vpc_id = aws_vpc.tf-vpc.id

  tags = {
    Name = "tf-gw"
  }
}

resource "aws_route_table" "tf-route" {
  vpc_id = aws_vpc.tf-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf-gw.id
  }

  tags = {
    Name = "tf-route"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.tf-subnet.id
  route_table_id = aws_route_table.tf-route.id
}

resource "aws_security_group" "tf-sg1" {
  name        = "tf-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.tf-vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-sg1"
  }
}

resource "aws_instance" "TF-EC2" {
  ami                    = "ami-0567f647e75c7bc05"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.tf-sg.id]
  subnet_id              = aws_subnet.tf-subnet.id
  key_name               = "mySSH"
  user_data              = <<-EOF
            #!/bin/bash
            sudo apt update -y
            sudo apt upgrade -y
            sudo apt install nginx -y
            #sudo bash -c 'echo your very first webserver > /var/www/html/index.html'
            EOF

  tags = {
    Name = "TF-EC2"
  }
}

resource "aws_eip" "tf-eip" {
  instance = aws_instance.TF-EC2.id
  vpc      = true
}

output "eip" {
  value = aws_eip.tf-eip.public_ip
}
