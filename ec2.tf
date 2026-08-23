resource "aws_key_pair" "main" {
  key_name   = var.key_pair_name
  public_key = file("/home/nalita/.ssh/id_ed25519.pub")
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-arm64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  control_subnet_id = module.vpc.public_subnet_ids[0]
}

resource "aws_instance" "ec2_control" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.ec2_type
  subnet_id              = local.control_subnet_id
  vpc_security_group_ids = [module.sg_control.id]
  key_name               = aws_key_pair.main.key_name
  tags                   = { Name = "terra-k8s-control" }
  user_data              = <<-EOF
  #!/bin/bash
  set -euxo pipefail
  exec > >(tee -a /var/log/user-data.log) 2>&1

  TOKEN="$(curl -s -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 600" http://169.254.169.254/latest/api/token)"
  PUBLIC_HOSTNAME="$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-hostname)"
  PUBLIC_IPV4="$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)"
  PRIVATE_IPV4="$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)"
  
  apt-get update -y
  apt-get upgrade -y
  curl -sfL https://get.k3s.io\
  | K3S_TOKEN=${var.k3s_token} sh -s - server \
  --tls-san "$PUBLIC_HOSTNAME" \
  --tls-san "$PUBLIC_IPV4" \
  --tls-san "$PRIVATE_IPV4" 
  EOF
}

resource "aws_instance" "ec2_workers" {
  count                  = 2
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.ec2_type
  subnet_id              = module.vpc.public_subnet_ids[count.index % length(module.vpc.public_subnet_ids)]
  vpc_security_group_ids = [module.sg_worker.id]
  key_name               = aws_key_pair.main.key_name
  tags                   = { Name = "terra-k8s-worker-${count.index}" }
  user_data              = <<-EOF
  #!/bin/bash
  set -euxo pipefail
  exec > >(tee -a /var/log/user-data.log) 2>&1
   
  apt-get update -y
  apt-get upgrade -y
  curl -sfL https://get.k3s.io \
  | K3S_URL=https://${aws_instance.ec2_control.private_ip}:6443 \
  K3S_TOKEN=${var.k3s_token} sh - 
  EOF
}

output "bastion_ip" {
  value = aws_instance.ec2_control.public_ip
}

output "bastion_dns" {
  value = aws_instance.ec2_control.public_dns
}
