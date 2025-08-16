variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1" # Mumbai
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing EC2 Key Pair for SSH"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR for SSH (restrict to your IP ideally)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_http_cidr" {
  description = "CIDR allowed for HTTP traffic"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ubuntu_ami_id" {
  description = "Optional override AMI"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Project = "flask-express-single-ec2"
  }
}