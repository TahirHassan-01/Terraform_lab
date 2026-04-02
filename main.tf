#---------Provider----------
provider "aws" {
  region = "us-west-2"
}
#---------instance----------

# 3. Find the Ubuntu Image (Same as before)
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

# 4. Create the Server and CONNECT everything
resource "aws_instance" "AB-lab-instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  key_name                    = "terraform-key"
  # NEW: Attach the Security Group
  vpc_security_group_ids      = [aws_security_group.TF_SG.id]

  # NEW: Assign a Public IP so you can reach it from Kali
  associate_public_ip_address = true

  tags = {
    Name = var.instance_name
  }
}






#-----------VPC-------------
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "MY-VPC-1001"
  }
}
# 2. Create a Subnet (The Room inside the building)
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "public-Subnet-1001"
  }
}
# 2.1 Create a Subnet (The Room inside the building)
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "private-Subnet-1001"
  }
}
# 3 : create IGW
resource "aws_internet_gateway" "myIgw"{
    vpc_id = aws_vpc.main_vpc.id
}
# 4 : route Tables for public subnet
resource "aws_route_table" "PublicRT"{
    vpc_id = aws_vpc.main_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myIgw.id
    }
}
# 5 : route table association public subnet
resource "aws_route_table_association" "PublicRTAssociation"{
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.PublicRT.id
}

#---------Security Group-----------
resource "aws_security_group" "TF_SG" {
  name        = "security group using Terraform"
  description = "security group using Terraform"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "TF_SG"
  }
}
#-------------key-pair--------------
# RSA key of size 4096 bits
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}



resource "aws_key_pair" "terraform-key" {
  key_name   = "terraform-key"
  public_key = tls_private_key.rsa.public_key_openssh
}



resource "local_file" "faah" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "keyfile"
}

#-----------S3------------
#terraform {
#  backend "s3" {
#    bucket         = "your-unique-terraform-state-bucket"
#    key            = "dev/terraform.tfstate"
#    region         = "us-west-2"
#  }
#}
