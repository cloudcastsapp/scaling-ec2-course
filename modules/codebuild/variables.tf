variable "infra_env" {
  type        = string
  description = "infrastructure environment"
}

variable "git_url" {
  type = string
  description = "Repository to connect to in GitHub"
}

variable "github_token" {
  type = string
  description = "GitHub Personal Access Token"
  sensitive   = true
}