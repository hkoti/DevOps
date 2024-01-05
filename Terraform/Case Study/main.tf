provider "aws" {
 region = "us-east-1"
}

resource "aws_vpc" "example" {
 cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example" {
 count = 2

 cidr_block = "10.0.${count.index}.0/24"
 vpc_id     = aws_vpc.example.id
}

resource "aws_security_group" "example" {
 name        = "example"
 description = "Example security group for EC2 instances"
 vpc_id      = aws_vpc.example.id

 ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
 }
}

resource "aws_instance" "example" {
 count         = 2

 ami           = "ami-06aa3f7caf3a30282"
 instance_type = "t2.micro"

 vpc_security_group_ids = [aws_security_group.example.id]
 subnet_id              = aws_subnet.example[count.index].id

associate_public_ip_address = true

 user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y apache2
              sudo systemctl start apache2
              sudo systemctl enable apache2
              EOF
 tags = {
    Name = "example-instance-${count.index}"
 }
}

resource "aws_internet_gateway" "example" {
 vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "example" {
 vpc_id = aws_vpc.example.id

 route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
 }
}

resource "aws_route_table_association" "example" {
 count          = 2

 subnet_id      = aws_subnet.example[count.index].id
 route_table_id = aws_route_table.example.id
}
