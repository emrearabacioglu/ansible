provider "aws" {
  region = "eu-central-1"
}

variable instance_type {}
variable my_ip {}
variable public_key_location {}
variable env_prefix{}
variable ansible_server_ip {}

data "aws_ami" "amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# default VPC (no vpc_id given)
resource "aws_security_group" "ansible-sg" {
  name = "ansible-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip, var.ansible_server_ip]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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
    Name: "${var.env_prefix}-ansible-sg"
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name   = "ansible-jenkins"
  public_key = file(var.public_key_location)
}

resource "aws_instance" "ansible-server-1" {
  ami                    = data.aws_ami.amazon-linux-image.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ssh-key.key_name
  vpc_security_group_ids = [aws_security_group.ansible-sg.id]

  tags = {
    Name = "${var.env_prefix}-server"
  }
}

resource "aws_instance" "ansible-server-2" {
  ami                    = data.aws_ami.amazon-linux-image.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ssh-key.key_name
  vpc_security_group_ids = [aws_security_group.ansible-sg.id]

  tags = {
    Name = "${var.env_prefix}-server"
  }
}

