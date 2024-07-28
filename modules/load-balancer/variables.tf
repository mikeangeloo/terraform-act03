variable "vpc_id" {
  description = "The ID of the VPC where the load balancer will be created"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs to attach to the load balancer"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security Group ID for Load Balancer"
  type        = string
}