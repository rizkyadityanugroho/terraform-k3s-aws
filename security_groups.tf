data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  my_ip = "${chomp(data.http.my_ip.response_body)}/32"
}

module "sg_control" {
  source = "./modules/sg"
  name   = "terra-k8s-sg-server"
  vpc_id = module.vpc.vpc_id

  common_ingress = {
    ssh     = { cidr_blocks = [local.my_ip] }
    http    = { cidr_blocks = [local.my_ip] }
    k8s_api = { cidr_blocks = [local.my_ip] }
    https   = { cidr_blocks = [local.my_ip] }
  }
}

module "sg_worker" {
  source = "./modules/sg"
  name   = "terra-k8s-sg-worker"
  vpc_id = module.vpc.vpc_id

  common_ingress = {
    ssh           = { source_security_group_id = module.sg_control.id }
    kubelet       = { source_security_group_id = module.sg_control.id }
    flannel_vxlan = { source_security_group_id = module.sg_control.id }
  }

  custom_ingress = [
    {
      self        = true
      from_port   = 8472
      to_port     = 8472
      description = "Self Flannel VXLAN"
      name        = "sg-worker-self-flannel"
      protocol    = "udp"
    }
  ]
}

resource "aws_security_group_rule" "control_from_worker_flannel" {
  type                     = "ingress"
  from_port                = 8472
  to_port                  = 8472
  description              = "flannel vxlan from workers"
  protocol                 = "udp"
  source_security_group_id = module.sg_worker.id
  security_group_id        = module.sg_control.id
}
resource "aws_security_group_rule" "control_from_worker_api" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = module.sg_worker.id
  security_group_id        = module.sg_control.id
  description              = "k8s api from workers"
}

output "sg_control_id" {
  value = module.sg_control.id
}

output "sg_worker_id" {
  value = module.sg_worker.id
}
