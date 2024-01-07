# key-pair

resource "aws_key_pair" "ru-key" {
  for_each   = var.node-name
  key_name   = "${each.key}-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDjRO4YQmzvra2fvN4r/AKBTYSfNO3WaHJDT0UZxXmv6xemhLu92wGk4mghyBji58shxmKcyEjL2WWvqpG3XTmE7ju2ZwBUdRNFNCqQ1ku1XRblFm4fMv0kex8dHRKzs5CpCcacLRINmdLMNybe+OaLVPuhsAWjLzHK4qktg47jyiyXoxwxQGQqqBjTW0ifIp8ik+VPpRRqxT7rJF9euYUnNcaEv2525aQ6OHjGTdCTHwQf3GVaXcB0Vd89KZEGaXvCFfA+X/OP7JF8Wz7cZoKVHsxHNuF0VDv1+7cA7RN7c+pLwqCiI6l21KaCRbRxpJrBSwfeBqAR7/2tGS29RgnR7SV2engGcT6BWX+Aiz192Hakt59l/tu724euzAC2vNy8gN7FLa7Tx1UE6QzIA9wFs68n6mSuI5bo6X1WbOkFBOpqrM/GZCbYRGqPHE4jkI8hXbIUBtVvPJSDa69+07UOESLExtCY1oCqXk4JuKcBsIIYKoeUShifDCg0hiWThDc= devopslab@MBP-2"

}


# vpc
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"


  tags = {
    Name = "${var.name}-vpc"
  }
}

# create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# create a custom route table

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.name}-rt"
  }
}
# create a subnet

resource "aws_subnet" "subnet-1" {
  for_each          = var.node-name
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet-cidr[each.value]
  availability_zone = "us-east-1b"

  tags = {
    Name = "${each.value}-subnet"
  }
}

#create a subnet with route table

resource "aws_route_table_association" "a" {
  for_each = var.node-name
  subnet_id      = aws_subnet.subnet-1[each.key].id
  route_table_id = aws_route_table.prod-route-table.id
}


# security group

resource "aws_security_group" "allow_tls" {
  for_each = var.node-name
  name        = "${each.key}"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "TLS from VPC"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "TLS from VPC"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "TLS from VPC"
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "TLS from VPC"
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "TLS from VPC"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "TLS from VPC"
    from_port   = 2379
    to_port     = 2380
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

  ingress {
    description = "ICMP from VPC"
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${each.key}-sg"
  }
}

# create a network interface 

resource "aws_network_interface" "web-server-nic" {
  for_each = var.node-name
  subnet_id       = aws_subnet.subnet-1[each.key].id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_tls[each.key].id]
}

#Assign an elastic ip to the network interface

resource "aws_eip" "one" {
  for_each = var.node-name
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-nic[each.key].id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

# aws instance

resource "aws_instance" "web" {
  for_each          = var.node-name
  ami               = var.ami
  instance_type     = var.instance-type
  availability_zone = "us-east-1b"
  key_name          = aws_key_pair.ru-key[each.key].key_name

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic[each.key].id

  }


  tags = {
    Name = each.key
  }
}
