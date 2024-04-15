# Create a VPC
resource "aws_vpc" "vpc-demo" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "demo-subnet" {
  vpc_id                  = aws_vpc.vpc-demo.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev_public"
  }
}

resource "aws_internet_gateway" "igw-demo" {

  vpc_id = aws_vpc.vpc-demo.id

  tags = {
    Name = "ig_demo"
  }
}


# resource "aws_route_table" "demo-route" {
# vpc_id = aws_vpc.vpc-demo.id

# route = {
#     cidr_block = ""
#     aws_internet_gateway = aws_internet_gateway.ig_demo.id

# }

# route = {
#     ipv6_cidr_block = "::/0"
#     egress_only_gateway_id = aws
# }

# }

resource "aws_route_table" "demo-public-route" {
  vpc_id = aws_vpc.vpc-demo.id

  tags = {
    Name = "dev_public_rt"
  }
}


resource "aws_route" "default-route" {

  route_table_id         = aws_route_table.demo-public-route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw-demo.id
}


resource "aws_route_table_association" "route-association" {
  subnet_id      = aws_subnet.demo-subnet.id
  route_table_id = aws_route_table.demo-public-route.id
}


resource "aws_security_group" "dev-security-groups" {

  name        = "dev_sg"
  description = "dev security groups"
  vpc_id      = aws_vpc.vpc-demo.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

}

resource "aws_key_pair" "mtc_auth" {
  key_name   = "mtckey"
  public_key = file("~/.ssh/mtckey.pub")
}

resource "aws_instance" "dev_instances" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.ami.id

  tags = {
    name = "dev-instances"
  }

  key_name               = aws_key_pair.mtc_auth.id
  vpc_security_group_ids = [aws_security_group.dev-security-groups.id]
  subnet_id              = aws_subnet.demo-subnet.id
  user_data              = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }
}



