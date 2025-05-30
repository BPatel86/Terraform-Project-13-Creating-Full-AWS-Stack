# resource "<provider>_<resource_type>" "name" {
#    config options....
#    key = "value"
#    key2 = "another value"
# }
# In Terraform order doesn't matter, we can place subnet before VPC in code but it will create VPC first then subnet.

provider "aws" {
    region = "us-east-1"
    access_key = "XXXXX"
    secret_key = "XXXXX"
}

# 1. Create VPC

resource "aws_vpc" "dev-vpc" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "dev"
  }
}


# 2. Create Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dev-vpc.id

    tags = {
    Name = "dev-IGW"
  }
}

# 3. Create Custom Route Table

resource "aws_route_table" "dev-RT" {
  vpc_id = aws_vpc.dev-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "dev-RT"
  }
}
# 4. Create Subnet

resource "aws_subnet" "dev-Subnet" {
  vpc_id     = aws_vpc.dev-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "dev-Public-Subnet-1"
  }
}

# 5. Associate Subnet with route table

resource "aws_route_table_association" "RT-Associate" {

  subnet_id      = aws_subnet.dev-Subnet.id
  route_table_id = aws_route_table.dev-RT.id

}

# 6. Create Security Group to allow port 22,80,443

resource "aws_security_group" "allow_Web" {
  name        = "allow_Web"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.dev-vpc.id

   ingress {
    description = "Https from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    description = "Http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    description = "SSH from VPC"
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
    Name = "allow_Web_Dev"
  }
}

# 7. Create a network interface with an IP in the subnet that was created in step 4

# resource "aws_network_interface" "web-server-nic" {
#   subnet_id       = aws_subnet.dev-Subnet.id
#   private_ips     = ["10.1.1.50"]
#   security_groups = [aws_security_group.allow_Web.id]
#
# }

# 8. Assign an elastic IP to the network interface created in step 7

# resource "aws_eip" "one" {
#   vpc                       = true
#   network_interface         = aws_network_interface.web-server-nic.id
#   associate_with_private_ip = "10.1.1.50"
#   depends_on = [aws_internet_gateway.igw]
# }


# 9. Create Ubuntu server  and install/enable apache2


# resource "aws_instance" "web-server-instance" {
#   ami = "ami-0c4f7023847b90238"
#   instance_type = "t2.micro"
#   availability_zone = "us-east-1a"
#   key_name = "bhaskar"
#
# network_interface {
#   device_index = 0
#   network_interface_id = aws_network_interface.web-server-nic.id
# }
#
# user_data = <<-EOF
#             #!/bin/bash
#             sudo apt update -y
#             sudo apt install apache2 -y
#             sudo systemctl start apache2
#             sudo bash -c 'echo your very first web server > /var/www/html/index.html'
#             EOF
# tags = {
#   "Name" = "web-server"
# }
# }





#resource "aws_instance" "web" {
#  ami           = "ami-013f17f36f8b1fefb"
#  instance_type = "t2.micro"
#  tags = {
#    Name = "ApacheTomcat"
#  }
#}
