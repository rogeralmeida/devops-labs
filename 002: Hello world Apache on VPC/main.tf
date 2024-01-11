provider "aws" {
  region = "ap-southeast-2"
}

module "ami-ubuntu" {
  source  = "andreswebs/ami-ubuntu/aws"
  version = "2.0.0"
}

locals {
  ami_id = module.ami-ubuntu.ami_id
}

variable "azs" {
  description = "values for availability zones"
  type        = list(string)
  default     = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
}

resource "aws_vpc" "hello-world-apache-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name     = "hello-world-apache-vpc"
    employee = "Roger Almeida"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.hello-world-apache-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name     = "hello-world-apache-vpc"
    employee = "Roger Almeida"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.hello-world-apache-vpc.id
  tags = {
    Name     = "hello-world-apache-vpc"
    employee = "Roger Almeida"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.hello-world-apache-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
  tags = {
    Name     = "hello-world-apache-vpc"
    employee = "Roger Almeida"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

/**
  * Creates a security group to allow inbound and outbound HTTP traffic
*/
resource "aws_security_group" "http" {
  name        = "http"
  description = "Allow inbound and outbound HTTP traffic"

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name     = "hello-world-apache-vpc"
    employee = "Roger Almeida"
  }
}

/**
  * Creates an EC2 instance with Apache installed
  * and a simple "Hello, World!" HTML page
*/
resource "aws_instance" "hello-world-apache-instance" {
  ami             = local.ami_id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.http.name]
  subnet_id       = aws_subnet.public_subnet.id
  tags = {
    Name     = "hello-world-apache-vpc"
    employee = "Roger Almeida"
  }

  user_data = <<-EOF
        #!/bin/bash
        apt-get update
        apt-get install -y apache2
        echo "<html><body><h1>Hello, World!</h1></body></html>" > /var/www/html/index.html
        systemctl enable apache2
        systemctl start apache2
    EOF
}

output "instance-public-ip" {
  value = aws_instance.hello-world-apache-instance.public_ip
}

output "instance-public-dns" {
  value = aws_instance.hello-world-apache-instance.public_dns
}
