# Hello World Apache on VPC
On the previous example we were using the default VPC, which unless you are doing some small POC you should never use the default VPC.

> **Default VPC**:
My impression is that the Default VPC is targeted to people with no cloud experience, so it has some weird rules that you should never use on a real project. Even a side project.

## VPC
We are creating an [AWS VPC](https://docs.aws.amazon.com/vpc/) with the following configuration:
```ruby
resource "aws_vpc" "hello-world-apache-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name     = "hello-world-apache-vpc"
    employee = "Roger Almeida"
  }
}
```

The `cidr_block = "10.0.0.0/16"` supports up to a little short of 65,536 IPs inside our VPC. Remember that [some IP address are reserved by AWS](https://docs.aws.amazon.com/vpc/latest/userguide/subnet-sizing.html#subnet-sizing-ipv4).

### Subnets
For now we are creating only 1 subnet:
```ruby
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
```

* The Subnet is attached to our VPC via: `vpc_id = aws_vpc.hello-world-apache-vpc.id`.
* The CIDR `10.0.1.0/24` allows us to use up to 256 IPs.

### Public Internet Access
Since we are creating a custom VPC, it will be completly locked by default. So we have to create a [Internet Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html) and create a [Route Table](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html) to allow traffic going and coming from the public internet. This entry is created in terraform via the `aws_route_table_association` which associates the Route Table with the Subnet we have created.

```ruby
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
```
