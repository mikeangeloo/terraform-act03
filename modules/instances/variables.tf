variable "instances" {
  description = "Map of instances to create"
  type = map(object({
    ami             = string
    instance_type   = string
    subnet_id       = string
    security_group_id = string
    key_name        = string
    tags            = map(string)
  }))
}