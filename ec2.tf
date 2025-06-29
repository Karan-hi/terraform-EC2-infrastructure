resource "aws_vpc" "vpc1" {
  cidr_block       = "192.168.100.0/24"
  instance_tenancy = "default"

  tags = {
    Name = "vpc-test"
  }
}
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "192.168.100.0/25"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet1-test"
  }
}
resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "192.168.100.128/25"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet2-test"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "internet-gw "
  }
}
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
resource "aws_security_group" "test" {
  name        = "sg01"
  description = "Allow http inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc1.id

  tags = {
    Name = "httpd"
  }
}
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.test.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80 
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.test.id
  cidr_ipv4         =  "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_route_table_association" "a" {
  subnet_id      = "${aws_subnet.subnet1.id}"
  route_table_id = "${aws_route_table.rt.id}"
}

resource "aws_instance" "machine1" {
  ami           = "ami-08fe5144e4659a3b3"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet1.id 
  key_name = "jenkins"
  vpc_security_group_ids = [aws_security_group.test.id]
  user_data = <<-EOF
   #!/bin/bash
   sudo su -
   sudo yum install nginx -y 
   sudo systemctl start nginx
   sudo systemctl enable nginx 
  EOF



  
  tags = {
    Name = "terraform_server1"
  }
}

resource "aws_route_table_association" "b" {
  subnet_id      = "${aws_subnet.subnet2.id}"
  route_table_id = "${aws_route_table.rt.id}"
}


resource "aws_instance" "machine2" {
  ami           = "ami-08fe5144e4659a3b3"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet2.id 
  key_name = "jenkins"
  vpc_security_group_ids = [aws_security_group.test.id]
  user_data = <<-EOF
   #!/bin/bash
   sudo su -
   sudo yum install nginx -y 
   sudo systemctl start nginx
   sudo systemctl enable nginx 
  EOF



  
  tags = {
    Name = "terraform_server2"
  }
}



resource "aws_lb_target_group" "target_group_test" {
  name     = "tg1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc1.id
}

resource "aws_lb_target_group_attachment" "attachment1" {
  target_group_arn = aws_lb_target_group.target_group_test.arn
  target_id       = aws_instance.machine1.id
  
}

resource "aws_lb_target_group_attachment" "attachment2" {
  target_group_arn = aws_lb_target_group.target_group_test.arn
  target_id       = aws_instance.machine2.id
  
}
resource "aws_lb" "alb" {
  name               = "test-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.test.id]
  subnet_mapping {
  subnet_id = aws_subnet.subnet1.id 
  }
  subnet_mapping {
    subnet_id = aws_subnet.subnet2.id 
  }


}