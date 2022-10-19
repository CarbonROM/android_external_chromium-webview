terraform {
  cloud {
    organization = "carbonrom"

    workspaces {
      name = "chromium-webview"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  chrome_shortversion = replace(
    replace(var.chrome_version, "/\\d+\\.\\d+\\./", ""),
  ".", "")
  name_suffix   = random_id.name.hex
  bucket_name   = "${var.bucket_name}-${local.name_suffix}"
  resource_name = "chromium-builder-${var.chrome_version}-${local.name_suffix}"
}

resource "random_id" "name" {
  keepers = {
    # Generate a new pet name each time we switch to a new AMI id
    ami_id = data.aws_ami.ubuntu.id
  }
  byte_length = 8
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["chromium-webview-cr11-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["803205869942"] # USA-RedDragon
}

resource "tls_private_key" "build_key" {
  rsa_bits  = 4096
  algorithm = "RSA"
}

resource "aws_key_pair" "build_key" {
  key_name   = local.resource_name
  public_key = tls_private_key.build_key.public_key_openssh
}

resource "aws_network_interface_sg_attachment" "builder_sg" {
  count                = var.parallel ? length(var.architectures_to_build) : 1
  security_group_id    = aws_security_group.builder.id
  network_interface_id = aws_network_interface.builder[count.index].id
}

resource "aws_cloudwatch_log_group" "builder" {
  name = local.resource_name
}

resource "aws_instance" "builder" {
  count                = var.parallel ? length(var.architectures_to_build) : 1
  ami                  = random_id.name.keepers.ami_id
  instance_type        = var.instance_type
  key_name             = aws_key_pair.build_key.key_name
  ebs_optimized        = true
  iam_instance_profile = aws_iam_instance_profile.builder.name
  user_data_base64 = base64encode(templatefile("${path.module}/user-data.sh", {
    chrome_version      = var.chrome_version
    chrome_shortversion = local.chrome_shortversion
    architectures       = var.parallel ? [var.architectures_to_build[count.index]] : var.architectures_to_build
    bucket_name         = local.bucket_name
    region              = var.region
    log_group_name      = aws_cloudwatch_log_group.builder.name
  }))

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.builder[count.index].id
  }

  root_block_device {
    volume_size           = 8
    encrypted             = false
    delete_on_termination = true
  }

  tags = {
    Name = "${local.resource_name}-${var.architectures_to_build[count.index]}"
  }

  volume_tags = {
    Name = "${local.resource_name}-${var.architectures_to_build[count.index]}"
  }
}

resource "aws_iam_instance_profile" "builder" {
  name = local.resource_name
  role = aws_iam_role.builder.name
}

resource "aws_iam_policy" "builder" {
  name        = local.resource_name
  description = "Policy for the chromium builder instance"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PutObjectsInBucket",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${local.bucket_name}/*"
      ]
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.builder.arn}",
        "${aws_cloudwatch_log_group.builder.arn}:log-stream:*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "builder" {
  name               = local.resource_name
  assume_role_policy = data.aws_iam_policy_document.builder.json
}

data "aws_iam_policy_document" "builder" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "builder" {
  role       = aws_iam_role.builder.name
  policy_arn = aws_iam_policy.builder.arn
}

resource "aws_security_group" "builder" {
  name        = local.resource_name
  description = "Allow SSH traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "build_output" {
  bucket        = local.bucket_name
  force_destroy = true
  tags = {
    Name = local.bucket_name
  }
}

resource "aws_s3_bucket_acl" "build_output" {
  bucket = aws_s3_bucket.build_output.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "build_output" {
  bucket = aws_s3_bucket.build_output.id
  rule {
    status = "Enabled"
    id     = "expire_all_files"
    expiration {
      days = 1
    }
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.resource_name
  cidr = "10.0.0.0/16"

  azs            = ["${var.region}a"]
  public_subnets = ["10.0.1.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Name = local.resource_name
  }
}

resource "aws_network_interface" "builder" {
  count       = var.parallel ? length(var.architectures_to_build) : 1
  subnet_id   = module.vpc.public_subnets[0]
  private_ips = ["10.0.1.${count.index + 10}"]

  tags = {
    Name = "${local.resource_name}-${var.architectures_to_build[count.index]}"
  }
}
