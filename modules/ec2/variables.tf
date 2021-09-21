variable "ami" {
  type        = string
  description = "AMI ID to use for EC2 instances"
}

variable "git_url" {
  type        = string
  description = "URL to git clone for ssh-based cloning"
}

variable "infra_env" {
  type        = string
  description = "infrastructure environment"
}

variable "infra_role" {
  type        = string
  description = "Server role, e.g. http vs queue"
  default     = "http"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type, e.g. t3.large"
}

variable "security_groups" {
  type        = list(string)
  description = "Security groups to assign the servers"
}

variable "ssh_key_name" {
  type        = string
  description = "Name of the EC2 key pair"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "launch template tags"
}

variable "instance_tags" {
  type        = map(string)
  default     = {}
  description = "tags for the ec2 instances"
}

variable "volume_tags" {
  type        = map(string)
  default     = {}
  description = "tags for the ebs volumes attached to instances"
}

variable "asg_subnets" {
  type        = list(string)
  description = "list of private subnet ID's to allow ASG to place instances"
}

variable "alb_subnets" {
  type        = list(string)
  default     = []
  description = "list of public subnet ID's to allow the load balancer to use"
}

variable "vpc_id" {
  type        = string
  description = "vpc to add ALB into"
}

variable "artifact_bucket" {
  type        = string
  description = "Application artifact bucket"
}

variable "min_size" {
  type = number
  description = "ASG minimum size"
}

variable "max_size" {
  type = number
  description = "ASG maximum size"
}

variable "desired_capacity" {
  type = number
  description = "ASG desired capacity"
}