provider "aws" {
  region = "eu-central-1"
}

variable instance_type {}
variable my_ip {}
variable public_key_location {}
variable ssh_key_private {}

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
    cidr_blocks = [var.my_ip]
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
}

resource "aws_key_pair" "ssh-key" {
  key_name   = "ansible-key"
  public_key = file(var.public_key_location)
}

resource "aws_instance" "ansible-server" {
  count                  = 2
  ami                    = data.aws_ami.amazon-linux-image.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ssh-key.key_name
  vpc_security_group_ids = [aws_security_group.ansible-sg.id]

  tags = {
    Name = "ansible-server-${count.index + 1}"
  }
}

resource "null_resource" "configure_server" {
  triggers = {
    trigger = join(",", aws_instance.ansible-server[*].public_ip)
  }
  provisioner "local-exec"{
    working_dir = "${path.module}/.."
    command     = "ansible-playbook --inventory ${join(",", aws_instance.ansible-server[*].public_ip)}, --private-key ${var.ssh_key_private} --user ec2-user deploy-docker.yaml"
  }
}

output "server-ips" {
  value = aws_instance.ansible-server[*].public_ip
}