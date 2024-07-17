# Temporary local variables
locals {
  aws_vpc_id               = "vpc-01899f3c4daef3226"
  aws_vpc_cidr             = "10.0.0.0/16"
  aws_vpc_public_subnet_id = "subnet-0fd906853c4f93bf8"
}

data "local_file" "ssh_public_key" {
  filename = pathexpand("~/.ssh/id_rsa.pub")
}

data "aws_ami" "atlantis" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_key_pair" "atlantis" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDl1vz2GLroKGBiQmtHx/lLOotslVExsCMS38MsjB1wO48sNlgQvoZRG+QMqn3TrbaTBC6DPMdKiGae3VPpiTKNQC38GepXfNOH+Sf7Fpv0uwLJu1XVr1KT2oSZzaVvI/xoXUjYOZcYaazwXhqpLOAxdp00B/XmsMLH+9mZZoYE1EvV9I3L1O7tzuAI/Z/PMtvTD8fIWkHhlDI68viBQNWehZAOsjlUG3UVgdnjs6jMuLwI0w5TFuY3y6jhj5eGcCsR++TV96phJgze9Ak4p/rbb7NcwGXUOGgizXI9CRYF6u/kdHZe9yBvChMzIm3/TiQ9XZC8bRi8mHGq9kk27Pf7"
}

resource "aws_security_group" "atlantis" {
  name   = "atlantis"
  vpc_id = local.aws_vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_everywhere" {
  security_group_id = aws_security_group.atlantis.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_everywhere" {
  security_group_id = aws_security_group.atlantis.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}

resource "aws_vpc_security_group_ingress_rule" "allow_atlantis_admin_everywhere" {
  security_group_id = aws_security_group.atlantis.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 4141
  ip_protocol       = "tcp"
  to_port           = 4141
}

resource "aws_iam_role" "atlantis" {
  name = "${var.env}-atlantis"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "atlantis_admin" {
  role       = aws_iam_role.atlantis.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "atlantis" {
  name = "${var.env}-atlantis"
  role = aws_iam_role.atlantis.name
}

resource "aws_instance" "atlantis" {
  ami                         = data.aws_ami.atlantis.id
  instance_type               = "t3.medium"
  associate_public_ip_address = true
  subnet_id                   = local.aws_vpc_public_subnet_id
  vpc_security_group_ids      = [aws_security_group.atlantis.id]
  key_name                    = aws_key_pair.atlantis.key_name

  iam_instance_profile = aws_iam_instance_profile.atlantis.id

  metadata_options {
    http_endpoint               = "enabled"
    instance_metadata_tags      = "enabled"
    http_put_response_hop_limit = 2
    http_protocol_ipv6          = "disabled"
    http_tokens                 = "optional"
  }

  tags = {
    Name = "${var.env}-atlantis-server"
  }

  user_data_replace_on_change = true
  user_data                   = <<-EOF
    #!/usr/bin/env bash

    yum install -y docker 

    #GH_USER=
    #GH_TOKEN=
    #GH_WEBHOOK_SECRET=
    #GH_HOSTNAME=
    #REPO_ALLOWLIST=

    #docker pull ghcr.io/runatlantis/atlantis:dev-debian-593c7c6
    #docker run -d -p8080:8080 -p4141:4141 \
    #  --atlantis-url="$URL" \
    #  --gh-user="$GH_USER" \
    #  --gh-token="$GH_TOKEN" \
    #  --gh-webhook-secret="$GH_WEBHOOK_SECRET" \
    #  --gh-hostname="$GH_HOSTNAME" \
    #  --repo-allowlist="$REPO_ALLOWLIST"
EOF
}

output "public_ip" {
  value = aws_instance.atlantis.public_ip
}
