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

resource "aws_vpc" "wordpress-apache-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name     = "wordpress-apache-vpc"
    employee = "Roger Almeida"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.wordpress-apache-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name     = "wordpress-public-subnet"
    employee = "Roger Almeida"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.wordpress-apache-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = false
  tags = {
    Name     = "wordpress-private-subnet"
    employee = "Roger Almeida"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.wordpress-apache-vpc.id
  tags = {
    Name     = "wordpress-internet-gateway"
    employee = "Roger Almeida"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  depends_on = [ aws_internet_gateway.my_igw ]
  tags = {
    Name     = "wordpress-eip"
    employee = "Roger Almeida"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name     = "wordpress-nat-gateway"
    employee = "Roger Almeida"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.my_igw]
}

resource "aws_route_table" "private_route_table" {

  vpc_id = aws_vpc.wordpress-apache-vpc.id

  route {
    # cidr_block     = aws_subnet.private_subnet.cidr_block
    cidr_block =  "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name     = "wordpress-private-route-table"
    employee = "Roger Almeida"
  }

}

resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.wordpress-apache-vpc.id

  route {
    # cidr_block =  aws_subnet.public_subnet.cidr_block
    cidr_block =  "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }


  tags = {
    Name     = "wordpress-public-route-table"
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
  vpc_id      = aws_vpc.wordpress-apache-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name     = "wordpress-http-sg"
    employee = "Roger Almeida"
  }
}

resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "Allow inbound SSH traffic"
  vpc_id      = aws_vpc.wordpress-apache-vpc.id

  ingress {
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
    Name     = "wordpress-ssh-sg"
    employee = "Roger Almeida"
  }
}

resource "aws_security_group" "mysql" {
  name        = "mysql"
  description = "Allow inbound MySQL traffic"
  vpc_id      = aws_vpc.wordpress-apache-vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "wordpress-mysql-sg"
    employee = "Roger Almeida"
  }
}

resource "aws_security_group" "icmp" {
  name        = "icmp"
  description = "Allow inbound and outbound HTTP traffic"
  vpc_id      = aws_vpc.wordpress-apache-vpc.id

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "wordpress-ping-sg"
    employee = "Roger Almeida"
  }
}


resource "aws_key_pair" "existing-m1-kp" {
  public_key = file("./m1-kp.pub")
}

resource "aws_instance" "wordpress-db-server" {
  ami                    = local.ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.mysql.id, aws_security_group.icmp.id]
  key_name               = aws_key_pair.existing-m1-kp.key_name
  user_data              = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y mysql-server
    systemctl enable mysql
    systemctl start mysql

    # Set password with `debconf-set-selections` You don't have to enter it in prompt
    debconf-set-selections <<< "mysql-server mysql-server/root_password password secret" # new password for the MySQL root user
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password secret" # repeat password for the MySQL root user

    # Other Code.....
    mysql --user=root --password=secret << EOFMYSQLSECURE
      DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
      DELETE FROM mysql.user WHERE User='';
      DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
      CREATE DATABASE wordpress;
      CREATE USER wordpress@'%' IDENTIFIED BY 'secret';
      GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER ON wordpress.* TO wordpress;
      FLUSH PRIVILEGES;
    EOFMYSQLSECURE
  EOF

  depends_on = [ aws_nat_gateway.nat_gateway ]
  tags = {
    Name     = "wordpress-db-server"
    employee = "Roger Almeida"
  }
}
/**
  * Creates an EC2 instance with Apache installed
  * and a simple "Hello, World!" HTML page
*/
resource "aws_instance" "hello-world-apache-instance" {
  ami                    = local.ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.http.id, aws_security_group.ssh.id]
  key_name               = aws_key_pair.existing-m1-kp.key_name
  user_data              = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y apache2 php libapache2-mod-php php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip
    systemctl enable apache2
    systemctl start apache2

    wget https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz
    cp -R wordpress/* /var/www/html/
    chown -R www-data:www-data /var/www/html/
  EOF

  depends_on = [ aws_nat_gateway.nat_gateway ]
  tags = {
    Name     = "wordpress-apache-server"
    employee = "Roger Almeida"
  }
}

output "instance-public-ip" {
  value = aws_instance.hello-world-apache-instance.public_ip
}

output "instance-public-dns" {
  value = aws_instance.hello-world-apache-instance.public_dns
}

output "db-instance-private-ip" {
  value = aws_instance.wordpress-db-server.private_ip
}