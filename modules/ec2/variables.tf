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