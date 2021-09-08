variable "infra_env" {
  type        = string
  description = "infrastructure environment"
}

variable "deploy_groups" {
  type = map(map(string))
  description = "Configure multiple deployment groups"
}