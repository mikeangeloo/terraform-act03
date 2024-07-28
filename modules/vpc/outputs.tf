
output "vpc_id" {
  value = aws_vpc.main.id
}

output "app_subnet_id" {
  value = aws_subnet.app_subnet.id
}

output "db_subnet_id" {
  value = aws_subnet.db_subnet.id
}