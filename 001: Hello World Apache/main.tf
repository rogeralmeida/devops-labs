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
}

/**
  * Creates an EC2 instance with Apache installed
  * and a simple "Hello, World!" HTML page
*/
resource "aws_instance" "hello-world-apache-instance" {
  ami             = local.ami_id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.http.name]

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
