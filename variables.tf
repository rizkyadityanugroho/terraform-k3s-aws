variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "vpc_name" {
  type        = string
  description = "Name tag for the VPC"
}

variable "vpc_az_count" {

  type        = number
  description = "Number of availability zones to spread subnets across"
}

variable "vpc_host_bits" {
  type        = number
  description = "Host bits for subnet CIDR calculation"
}

variable "key_pair_name" {
  type        = string
  description = "SSH Key Pair Name"
}

variable "ec2_type" {
  type        = string
  description = "EC2 instance type"
}

variable "k3s_token" {
  type        = string
  description = "Secret token for K3S cluster"
}
