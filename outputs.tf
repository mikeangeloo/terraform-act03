output "db_instance_public_ip" {
  value = module.instances.public_ips["mean-db"]
}

output "db_instance_private_ip" {
  value = module.instances.private_ips["mean-db"]
}

output "app_instance_public_ip" {
  value = module.instances.public_ips["mean-app"]
}

output "app_instance_private_ip" {
  value = module.instances.private_ips["mean-app"]
}

output "lb_dns_name" {
  value = module.load-balancer.lb_dns
}