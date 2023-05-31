variable "base_cidr_block" {
  description = "The CIDR block for the VPC."
  default     = "192.168.0.0/16"
}

variable "env_name" {
  description = "The name of the environment."
  default     = "srhoton-dev"
}

variable "github_token" {
  description = "The GitHub Token to be used for the CodePipeline"
  type        = string
  default     = "ghp_6kMzjWdwV2Vxs2iNlyZ8kP3j2UyJ3D2vBKb"
}

variable "account_id" {
  description = "id of the active account"
  type        = string
  default     = "705740530616"
}

variable "container_name" {
  description = "The name of the container to be deployed"
  type        = string
  default     = "cicd_poc"
}
