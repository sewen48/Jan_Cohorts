# configured aws provider with proper credentials
provider "aws" {
  region     = "us-east-1"
  profile    = "ganiyy"
}


# Create a VPC

resource "aws_vpc" "prodvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "production_vpc"
  }
}

# Create a Subnet

resource "aws_subnet" "prodsubnet1" {
  vpc_id            = aws_vpc.prodvpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "prod-subnet"
  }
}

#Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prodvpc.id

  tags = {
    Name = "New"
  }
}

# Create a Route Table
resource "aws_route_table" "prodroute" {
  vpc_id = aws_vpc.prodvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "RT"
  }
}


#Associate subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.prodsubnet1.id
  route_table_id = aws_route_table.prodroute.id
}


# Create a Security Group
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow webserver inbound traffic"
  vpc_id      = aws_vpc.prodvpc.id

  ingress {
    description = "Web Traffic from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" # Any ip address/ any protocol
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_instance" "firstinstance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  subnet_id              = aws_subnet.prodsubnet1.id
  key_name               = "zeeKP"
  availability_zone      = "us-east-1a"
  user_data              =  "${file("install_jenkins.sh")}"


  tags = {
    Name = "Jenkins_Server"
  }
}


resource "aws_instance" "secondinstance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  subnet_id              = aws_subnet.prodsubnet1.id
  key_name               = "zeeKP"
  availability_zone      = "us-east-1a"
  user_data              =  "${file("install_tomcat.sh")}"
  


  tags = {
    Name = "Tomcat_Server"
  }
}


# use data source to get a registered ubuntu ami
data "aws_ami" "ubuntu" {

  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# print the url of the jenkins server
output "Jenkins_website_url" {
  value     = join ("", ["http://", aws_instance.firstinstance.public_ip, ":", "8080"])
  description = "Jenkins Server is firstinstance"
}

# print the url of the tomcat server
output "Tomcat_website_url1" {
  value     = join ("", ["http://", aws_instance.secondinstance.public_ip, ":", "8080"])
  description = "Tomcat Server is secondinstance"
}

#output "website-url" {
 # value       = "${aws_instance.firstinstance.*.public_ip}"
  #description = "PublicIP address details"
#}
# aws_instance.ec2_instance.public_dns




